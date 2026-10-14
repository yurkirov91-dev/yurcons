"""Import one accessible file into a case, preserving originals and existing files."""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", help="File path accessible in this execution environment")
    parser.add_argument("--case", required=True, help="Unique case ID")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}", args.case):
        parser.error("Invalid case ID")
    if re.match(r"^[A-Za-z]:[\\/]", args.source):
        parser.error("Windows path is unavailable in cloud; upload the file or use local Codex")
    source = Path(args.source).expanduser().resolve(strict=True)
    if not source.is_file():
        parser.error("Source must be a file")
    case = (ROOT / "01_Cases" / args.case).resolve()
    if not case.is_relative_to(ROOT / "01_Cases"):
        parser.error("Case path escapes project")
    template = ROOT / "03_Templates" / "CASE"
    for item in template.rglob("*"):
        if not (case / item.relative_to(template)).resolve().is_relative_to(case):
            parser.error("Existing symlink escapes case")
    case.mkdir(parents=True, exist_ok=True)
    for item in template.rglob("*"):
        target = case / item.relative_to(template)
        if not target.resolve().is_relative_to(case):
            parser.error("Existing symlink escapes case")
        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        elif not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open("xb") as out:
                out.write(item.read_bytes())
    destination = case / "01_Originals" / source.name
    if not destination.resolve().is_relative_to(case):
        parser.error("Destination escapes case")
    data = source.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if destination.exists():
        if destination.read_bytes() != data:
            parser.error("Existing original differs; choose a distinct source filename")
        action = "already_present"
    else:
        with destination.open("xb") as out:
            out.write(data)
        action = "imported"
    receipt = case / "02_Extracted" / (source.name + ".import.json")
    if not receipt.resolve().is_relative_to(case):
        parser.error("Receipt path escapes case")
    record = {"file": source.name, "sha256": digest, "bytes": len(data),
              "status": "imported_not_analyzed"}
    if not receipt.exists():
        with receipt.open("x", encoding="utf-8") as out:
            json.dump(record, out, ensure_ascii=False, indent=2)
    print(json.dumps({"action": action, "destination": str(destination),
                      "sha256": digest}, ensure_ascii=False))


if __name__ == "__main__":
    main()
