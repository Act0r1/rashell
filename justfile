root := justfile_directory()
home := env_var("HOME")
qs := env_var_or_default("RASHELL_QUICKSHELL", home + "/.local/opt/rashell-runtime/quickshell")
config_link := home + "/.config/quickshell/rashell"
selector := home + "/.local/state/noctalia-shell-version"

_default:
    @just --list

install:
    #!/usr/bin/env bash
    set -euo pipefail
    link="{{config_link}}"
    root="{{root}}"
    mkdir -p "$(dirname "$link")"
    if [[ -L "$link" ]]; then
        [[ "$(readlink -f "$link")" == "$root" ]] || { echo "Refusing to replace $link" >&2; exit 1; }
    elif [[ -e "$link" ]]; then
        echo "Refusing to replace non-symlink $link" >&2
        exit 1
    else
        ln -s "$root" "$link"
    fi
    echo "Rashell linked at $link"

start: install
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$(dirname "{{selector}}")"
    printf 'rashell\n' > "{{selector}}"
    pkill -x noctalia 2>/dev/null || true
    "{{qs}}" -c rashell kill 2>/dev/null || true
    "{{qs}}" --no-color -c rashell -d
    echo "Rashell started"

run: start

stop:
    #!/usr/bin/env bash
    set -euo pipefail
    "{{qs}}" -c rashell kill 2>/dev/null || true
    mkdir -p "$(dirname "{{selector}}")"
    printf 'v5\n' > "{{selector}}"
    if ! pgrep -x noctalia >/dev/null; then
        noctalia -d >"${XDG_RUNTIME_DIR:-/tmp}/rashell-noctalia.log" 2>&1
    fi
    echo "Rashell stopped; Noctalia V5 started"

noctalia: stop

uninstall: stop
    #!/usr/bin/env bash
    set -euo pipefail
    link="{{config_link}}"
    root="{{root}}"
    if [[ -L "$link" && "$(readlink -f "$link")" == "$root" ]]; then
        rm "$link"
        echo "Removed $link"
    elif [[ -e "$link" ]]; then
        echo "Refusing to remove $link because it is not Rashell's symlink" >&2
        exit 1
    else
        echo "Rashell link is already absent"
    fi

remove: uninstall

themes:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 - "{{root}}/core/themes.json" <<'PY'
    import json
    import sys
    from pathlib import Path

    catalog = json.loads(Path(sys.argv[1]).read_text())
    print("\n".join(theme["id"] for theme in catalog))
    PY

theme name:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 - "{{root}}/config.json" "{{root}}/core/themes.json" "{{name}}" <<'PY'
    import json
    import os
    import sys
    from pathlib import Path

    path = Path(sys.argv[1])
    catalog_path = Path(sys.argv[2])
    name = sys.argv[3]
    allowed = [theme["id"] for theme in json.loads(catalog_path.read_text())]
    if name not in allowed:
        raise SystemExit(f"Unknown theme: {name}. Choose from: {', '.join(allowed)}")
    data = json.loads(path.read_text())
    data["theme"] = name
    temporary = path.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(data, indent=2) + "\n")
    os.replace(temporary, path)
    print(f"Theme set to {name}")
    PY

shaders:
    cd "{{root}}" && scripts/build-shaders.sh

test:
    cd "{{root}}" && python -m unittest discover -s tests -p 'test_*.py' -v
    cd "{{root}}" && QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/tst_launcher_search.qml -o -,txt
    cd "{{root}}" && tests/smoke.sh
