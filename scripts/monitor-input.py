import argparse
import json
import os
import re
import subprocess


def ddc(*args: str) -> str:
    result = subprocess.run(
        ["ddcutil", *args], capture_output=True, text=True, timeout=25,
        env={**os.environ, "LC_ALL": "C"},
    )
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout).strip() or "Monitor did not respond")
    return result.stdout


def hex_value(value: str) -> int:
    return int(value, 16)


def current_input(selector: tuple[str, str]) -> int:
    current = re.search(r"sl=0x([0-9a-fA-F]+)", ddc(*selector, "getvcp", "60"))
    if not current:
        raise RuntimeError("Could not read the current input")
    return int(current[1], 16)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output")
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--set", dest="source", type=hex_value)
    action.add_argument("--toggle", nargs=2, metavar=("HOME", "AWAY"), type=hex_value)
    args = parser.parse_args()
    try:
        displays = re.split(r"(?m)^(?:Invalid )?Display ", ddc("detect"))[1:]
        matches = [block for block in displays if re.search(
            r"DRM_connector:\s+card\d+-" + re.escape(args.output) + r"\s", block
        )]
        if len(matches) != 1:
            raise RuntimeError("No unique DDC/CI monitor found for " + args.output)
        bus = re.search(r"I2C bus:\s+/dev/i2c-(\d+)", matches[0])
        model = re.search(r"Model:\s+([^\n]+)", matches[0])
        if not bus:
            raise RuntimeError("Monitor I2C bus is unavailable")
        selector = ("--bus", bus[1])
        capabilities = ddc(*selector, "capabilities")
        feature = re.search(r"Feature: 60 \([^\n]+\)(.*?)(?=\n\s*Feature:|\Z)", capabilities, re.S)
        if not feature:
            raise RuntimeError("Monitor does not advertise input switching")
        inputs = [{"value": int(value, 16), "label": label.strip().replace("HDMI-", "HDMI ").replace("DisplayPort-1", "DisplayPort")}
                  for value, label in re.findall(r"(?m)^\s+([0-9a-fA-F]{2}): ([^\n]+)", feature[1])]
        if not inputs:
            raise RuntimeError("Monitor did not report available inputs")
        if args.toggle:
            home, away = args.toggle
            args.source = away if current_input(selector) == home else home
        if args.source is not None:
            if args.source not in [item["value"] for item in inputs]:
                raise RuntimeError("Input is not supported by this monitor")
            ddc(*selector, "setvcp", "60", hex(args.source), "--noverify")
            print(json.dumps({"sent": True}))
            return
        print(json.dumps({"model": model[1].strip() if model else args.output,
                          "inputs": inputs, "current": current_input(selector)}))
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(json.dumps({"error": str(error)}))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
