#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
directory="${2:-${HOME}/Pictures/Screenshots}"
capture_mode="${3:-region}"
audio_mode="${4:-none}"
capture_target="${5:-}"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pid_file="${runtime_dir}/rashell-screen-recorder-${UID}.pid"
paused_file="${runtime_dir}/rashell-screen-recorder-${UID}.paused"
selector_pid_file="${runtime_dir}/rashell-screen-selector-${UID}.pid"

if [[ "$directory" == "~" ]]; then
    directory="$HOME"
elif [[ "$directory" == "~/"* ]]; then
    directory="$HOME/${directory#~/}"
fi

require() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing required tool: %s\n' "$1" >&2
        exit 20
    }
}

run_selector() {
    local selector_pid selector_status result_file
    result_file="$(mktemp)"
    slurp "$@" > "$result_file" 2>/dev/null &
    selector_pid=$!
    printf '%s\n' "$selector_pid" > "$selector_pid_file"

    set +e
    wait "$selector_pid"
    selector_status=$?
    set -e
    if [[ -f "$selector_pid_file" ]] && [[ "$(cat "$selector_pid_file")" == "$selector_pid" ]]; then
        rm -f "$selector_pid_file"
    fi
    if [[ "$selector_status" -ne 0 ]] || [[ ! -s "$result_file" ]]; then
        rm -f "$result_file"
        exit 10
    fi
    cat "$result_file"
    rm -f "$result_file"
}

select_region() {
    run_selector
}

select_output() {
    run_selector -o -r -f '%o'
}

active_pid() {
    local process_pid file="$1" expected_name="$2" attempt
    for attempt in {1..20}; do
        if [[ -f "$file" ]]; then
            process_pid="$(cat "$file")"
            if [[ "$process_pid" =~ ^[0-9]+$ ]] \
                && [[ -r "/proc/$process_pid/comm" ]] \
                && [[ "$(cat "/proc/$process_pid/comm")" == "$expected_name" ]]; then
                printf '%s' "$process_pid"
                return 0
            fi
        fi
        sleep 0.025
    done
    return 1
}

active_recorder_pid() {
    active_pid "$pid_file" "wf-recorder"
}

new_path() {
    local prefix="$1"
    local extension="$2"
    local stamp candidate suffix=0
    stamp="$(date +%Y-%m-%d_%H-%M-%S)"
    candidate="$directory/${prefix}_${stamp}.${extension}"
    while [[ -e "$candidate" ]]; do
        suffix=$((suffix + 1))
        candidate="$directory/${prefix}_${stamp}_${suffix}.${extension}"
    done
    printf '%s' "$candidate"
}

notify_saved() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Rashell capture" "Saved to $1"
    fi
}

case "$action" in
    select-region)
        require slurp
        select_region
        ;;

    select-output)
        require slurp
        select_output
        ;;

    screenshot)
        require grim
        require slurp
        require wl-copy
        geometry="$(select_region)"
        mkdir -p "$directory"
        output="$(new_path screenshot png)"
        grim -g "$geometry" "$output"
        wl-copy --type image/png < "$output"
        notify_saved "$output"
        printf '%s\n' "$output"
        ;;

    annotate)
        require grim
        require slurp
        require satty
        require wl-copy
        geometry="$(select_region)"
        mkdir -p "$directory"
        output="$(new_path screenshot-edited png)"
        temporary="$(mktemp --suffix=.png)"
        trap 'rm -f "$temporary"' EXIT
        grim -g "$geometry" "$temporary"
        satty --filename "$temporary" \
            --output-filename "$output" \
            --copy-command wl-copy \
            --save-after-copy \
            --early-exit save
        [[ -s "$output" ]] || exit 10
        wl-copy --type image/png < "$output"
        notify_saved "$output"
        printf '%s\n' "$output"
        ;;

    record)
        require slurp
        require wf-recorder

        recorder_args=()
        case "$capture_mode" in
            region)
                if [[ -n "$capture_target" ]]; then
                    geometry="$capture_target"
                else
                    geometry="$(select_region)"
                fi
                recorder_args+=(--geometry "$geometry")
                ;;
            output)
                if [[ -n "$capture_target" ]]; then
                    selected_output="$capture_target"
                else
                    selected_output="$(select_output)"
                fi
                recorder_args+=(--output "$selected_output")
                ;;
            *)
                printf 'Unknown capture mode: %s\n' "$capture_mode" >&2
                exit 2
                ;;
        esac

        audio_modules=()
        cleanup_audio() {
            local index
            if command -v pactl >/dev/null 2>&1; then
                for ((index=${#audio_modules[@]} - 1; index >= 0; index--)); do
                    pactl unload-module "${audio_modules[$index]}" >/dev/null 2>&1 || true
                done
            fi
            audio_modules=()
        }
        trap cleanup_audio EXIT

        if [[ "$audio_mode" != "none" ]]; then
            require pactl
            microphone_source="$(pactl get-default-source)"
            default_sink="$(pactl get-default-sink)"
            system_source="$(pactl list short sources | awk -v name="${default_sink}.monitor" '$2 == name { print $2; exit }')"
        fi

        case "$audio_mode" in
            none)
                ;;
            microphone)
                [[ -n "$microphone_source" ]] || {
                    printf 'No default microphone is configured\n' >&2
                    exit 20
                }
                recorder_args+=(--audio="$microphone_source")
                ;;
            system)
                [[ -n "$system_source" ]] || {
                    printf 'No monitor source for audio output: %s\n' "$default_sink" >&2
                    exit 20
                }
                recorder_args+=(--audio="$system_source")
                ;;
            both)
                [[ -n "$microphone_source" ]] || {
                    printf 'No default microphone is configured\n' >&2
                    exit 20
                }
                [[ -n "$system_source" ]] || {
                    printf 'No monitor source for audio output: %s\n' "$default_sink" >&2
                    exit 20
                }
                mix_name="rashell_capture_mix_${UID}_$$"
                module_id="$(pactl load-module module-null-sink sink_name="$mix_name")"
                audio_modules+=("$module_id")
                module_id="$(pactl load-module module-loopback source="$microphone_source" sink="$mix_name" latency_msec=20)"
                audio_modules+=("$module_id")
                module_id="$(pactl load-module module-loopback source="$system_source" sink="$mix_name" latency_msec=20)"
                audio_modules+=("$module_id")
                recorder_args+=(--audio="${mix_name}.monitor")
                ;;
            *)
                printf 'Unknown audio mode: %s\n' "$audio_mode" >&2
                exit 2
                ;;
        esac

        mkdir -p "$directory" "$runtime_dir"
        output="$(new_path recording mp4)"
        rm -f "$paused_file"
        wf-recorder "${recorder_args[@]}" -f "$output" &
        recorder_pid=$!
        printf '%s\n' "$recorder_pid" > "$pid_file"

        cleanup_recording() {
            if [[ -f "$pid_file" ]] && [[ "$(cat "$pid_file")" == "$recorder_pid" ]]; then
                rm -f "$pid_file"
            fi
            rm -f "$paused_file"
            cleanup_audio
        }
        trap cleanup_recording EXIT

        set +e
        wait "$recorder_pid"
        recorder_status=$?
        set -e
        [[ -s "$output" ]] || exit "$recorder_status"
        notify_saved "$output"
        printf '%s\n' "$output"
        ;;

    pause)
        recorder_pid="$(active_recorder_pid)" || {
            rm -f "$pid_file" "$paused_file"
            printf 'No active screen recording\n' >&2
            exit 30
        }
        kill -STOP "$recorder_pid"
        touch "$paused_file"
        ;;

    resume)
        recorder_pid="$(active_recorder_pid)" || {
            rm -f "$pid_file" "$paused_file"
            printf 'No active screen recording\n' >&2
            exit 30
        }
        kill -CONT "$recorder_pid"
        rm -f "$paused_file"
        ;;

    stop)
        if recorder_pid="$(active_recorder_pid)"; then
            if [[ -f "$paused_file" ]]; then
                kill -CONT "$recorder_pid"
            fi
            kill -INT "$recorder_pid"
            exit 0
        fi

        rm -f "$pid_file" "$paused_file"
        if selector_pid="$(active_pid "$selector_pid_file" "slurp")"; then
            kill -TERM "$selector_pid"
        fi
        rm -f "$selector_pid_file"
        ;;

    *)
        printf 'Usage: %s select-region|select-output|screenshot|annotate|record|pause|resume|stop [directory] [region|output] [none|system|microphone|both] [selection]\n' "$0" >&2
        exit 2
        ;;
esac
