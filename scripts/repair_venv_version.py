"""Record the actual Python patch version for editor environment discovery."""
from pathlib import Path
import platform
import re
import sys


def main():
    project_root = Path(__file__).resolve().parents[1]
    venv = Path(sys.prefix).resolve()
    if venv.name != ".venv" or venv.parent.parent != project_root:
        raise RuntimeError("Run this script with a course's .venv Python interpreter.")
    version = platform.python_version()
    expected = (venv.parent / ".python-version").read_text(encoding="utf-8").strip()
    if version != expected:
        raise RuntimeError(f"Expected Python {expected}, but this environment runs {version}.")

    config = venv / "pyvenv.cfg"
    original = config.read_bytes().decode("utf-8")
    newline = "\r\n" if "\r\n" in original else "\n"
    updated = original
    # uv may record only major.minor. VS Code represents an unknown patch as -1.
    # Keep both the stdlib venv key and uv's key in sync with the real interpreter.
    for key in ("version", "version_info"):
        pattern = rf"(?m)^{key}[ \t]*=[^\r\n]*"
        entry = f"{key} = {version}"
        if re.search(pattern, updated):
            updated = re.sub(pattern, entry, updated)
        else:
            if updated and not updated.endswith(("\n", "\r")):
                updated += newline
            updated += entry + newline
    if updated != original:
        config.write_bytes(updated.encode("utf-8"))
    print(f"Environment discovery version: {version}")


if __name__ == "__main__":
    main()
