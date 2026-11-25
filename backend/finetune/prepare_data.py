"""Convert a source dataset of OBD-II fault-code explanations into OpenAI
chat-completion fine-tuning JSONL, matching AutoIntel's prompt and JSON schema.

Source format (JSON list or CSV). Required fields: `code`, `plain_explanation`,
`severity`. Optional: `raw_description`, `likely_causes`, `recommended_action`.

    [
      {
        "code": "P0301",
        "plain_explanation": "Cylinder 1 is misfiring...",
        "likely_causes": ["Worn spark plug", "Faulty ignition coil"],
        "severity": "high",
        "recommended_action": "Schedule service promptly."
      }
    ]

Usage (from the backend/ directory, with the venv active):

    python -m finetune.prepare_data finetune/seed_codes.json -o finetune/finetune.jsonl
"""

import argparse
import csv
import json
import sys
from pathlib import Path

# Make `prompts` importable whether run as a script or `python -m`.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from prompts.diagnostic_prompt import (  # noqa: E402
    DIAGNOSTIC_SYSTEM_PROMPT,
    build_diagnostic_prompt,
)

REQUIRED = {"code", "plain_explanation", "severity"}
ALLOWED_SEVERITIES = {"low", "medium", "high", "critical"}


def load_source(path: str) -> list[dict]:
    p = Path(path)
    if p.suffix.lower() == ".csv":
        with p.open(newline="", encoding="utf-8") as f:
            return list(csv.DictReader(f))
    with p.open(encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise SystemExit(f"Expected a JSON array in {path}, got {type(data).__name__}")
    return data


def parse_list(value) -> list[str]:
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return [str(x).strip() for x in value if str(x).strip()]
    s = str(value).strip()
    if s.startswith("["):
        try:
            return [str(x).strip() for x in json.loads(s)]
        except json.JSONDecodeError:
            pass
    return [x.strip() for x in s.split(",") if x.strip()]


def assistant_content(row: dict) -> str:
    obj = {
        "plain_explanation": str(row["plain_explanation"]).strip(),
        "likely_causes": parse_list(row.get("likely_causes")),
        "symptoms": parse_list(row.get("symptoms")),
        "severity": str(row["severity"]).strip().lower(),
        "recommended_action": str(row.get("recommended_action") or "").strip(),
        "repair_difficulty": str(row.get("repair_difficulty") or "medium").strip().lower(),
        "estimated_cost": str(row.get("estimated_cost") or "").strip(),
    }
    return json.dumps(obj, ensure_ascii=False)


def build_line(row: dict) -> dict:
    user = build_diagnostic_prompt(
        str(row["code"]).strip(),
        row.get("raw_description") or None,
    )
    return {
        "messages": [
            {"role": "system", "content": DIAGNOSTIC_SYSTEM_PROMPT},
            {"role": "user", "content": user},
            {"role": "assistant", "content": assistant_content(row)},
        ]
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", help="path to source JSON or CSV")
    ap.add_argument("-o", "--output", default="finetune.jsonl")
    args = ap.parse_args()

    rows = load_source(args.source)
    lines: list[dict] = []
    skipped: list[tuple[int, str]] = []

    for i, row in enumerate(rows):
        missing = REQUIRED - set(row)
        if missing:
            skipped.append((i, f"missing {sorted(missing)}"))
            continue
        severity = str(row["severity"]).strip().lower()
        if severity not in ALLOWED_SEVERITIES:
            skipped.append((i, f"invalid severity {row['severity']!r}"))
            continue
        lines.append(build_line(row))

    out = Path(args.output)
    with out.open("w", encoding="utf-8") as f:
        for line in lines:
            f.write(json.dumps(line, ensure_ascii=False) + "\n")

    print(f"Wrote {len(lines)} examples to {out}")
    for idx, reason in skipped:
        print(f"  skipped row {idx}: {reason}")


if __name__ == "__main__":
    main()
