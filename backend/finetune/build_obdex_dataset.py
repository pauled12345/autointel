"""Convert the OBDex dataset (https://github.com/foerbsnavi/OBDex) into
AutoIntel's fine-tuning row format, ready to feed `prepare_data.py`.

OBDex ships 9,533 generic OBD-II codes as YAML with title, description, common
causes (with likelihood), symptoms, repair difficulty/cost and flags. This maps
those into the fields AutoIntel's LLM emits:

    code, raw_description, plain_explanation, likely_causes, severity,
    recommended_action

Usage (from backend/, venv active):

    python -m finetune.build_obdex_dataset --obdex-dir C:\\path\\to\\obdex\\data -o finetune\\obdex_rows.json
    python -m finetune.prepare_data finetune\\obdex_rows.json -o finetune\\finetune.jsonl
"""

import argparse
import json
from pathlib import Path

import yaml

_LIKELIHOOD_ORDER = {"high": 0, "medium": 1, "low": 2}
_FAMILIES = ("P0xxx", "P2xxx", "P3xxx", "B0xxx", "C0xxx", "U0xxx", "U3xxx")


def derive_severity(flags: dict, difficulty: str | None) -> str:
    """Map OBDex flags + repair difficulty to AutoIntel severity.

    - critical: may enter limp mode AND the repair is hard/shop-only (urgent)
    - high:     may enter limp mode, or MIL on with a hard/shop-only repair
    - medium:   MIL on (check engine light)
    - low:      everything else (emissions / convenience)
    """
    if flags.get("limp_mode_possible") and difficulty in ("hard", "shop_only"):
        return "critical"
    if flags.get("limp_mode_possible"):
        return "high"
    if flags.get("mil"):
        return "high" if difficulty in ("hard", "shop_only") else "medium"
    return "low"


def derive_action(flags: dict, difficulty: str | None) -> str:
    if flags.get("limp_mode_possible") and difficulty in ("hard", "shop_only"):
        return "Stop driving if possible and have the vehicle inspected immediately."
    if flags.get("limp_mode_possible"):
        return (
            "Drive cautiously to a workshop as soon as possible — the vehicle "
            "may enter reduced-power (limp) mode."
        )
    if flags.get("mil") or difficulty in ("hard", "shop_only"):
        return "Schedule service promptly and avoid hard driving until diagnosed."
    if flags.get("emissions_relevant"):
        return "Safe to drive. Have it checked at your next service; it may fail an emissions inspection."
    return "Safe to drive. Address at your convenience."


def causes(entry: dict, max_causes: int) -> list[str]:
    raw = entry.get("common_causes") or []
    ordered = sorted(raw, key=lambda c: _LIKELIHOOD_ORDER.get(c.get("likelihood"), 2))
    labels = [c["label"]["en"] for c in ordered if c.get("label", {}).get("en")]
    return labels[:max_causes]


def symptoms(entry: dict) -> list[str]:
    raw = entry.get("symptoms") or []
    return [s["en"].strip() for s in raw if isinstance(s, dict) and s.get("en")]


def repair_difficulty(repair: dict) -> str:
    d = repair.get("difficulty") or "medium"
    return "hard" if d == "shop_only" else d


def estimated_cost(repair: dict) -> str:
    cost = repair.get("estimated_cost_eur")
    if isinstance(cost, list) and len(cost) == 2:
        return f"${cost[0]:.0f} - ${cost[1]:.0f}"
    return "Varies — needs diagnosis"


def to_row(entry: dict, max_causes: int) -> dict:
    flags = entry.get("flags") or {}
    repair = entry.get("repair") or {}
    difficulty = repair.get("difficulty")
    return {
        "code": entry["code"],
        "raw_description": (entry.get("title") or {}).get("en"),
        "plain_explanation": (entry.get("description") or {}).get("en"),
        "likely_causes": causes(entry, max_causes),
        "symptoms": symptoms(entry),
        "severity": derive_severity(flags, difficulty),
        "recommended_action": derive_action(flags, difficulty),
        "repair_difficulty": repair_difficulty(repair),
        "estimated_cost": estimated_cost(repair),
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--obdex-dir", required=True, help="path to the cloned OBDex `data/` directory")
    ap.add_argument("-o", "--output", default="obdex_rows.json")
    ap.add_argument("--max-causes", type=int, default=5, help="max causes per code (default 5)")
    ap.add_argument("--limit", type=int, default=0, help="cap the number of codes (0 = all)")
    args = ap.parse_args()

    generic_dir = Path(args.obdex_dir) / "generic"
    if not generic_dir.is_dir():
        raise SystemExit(f"not found: {generic_dir} (point --obdex-dir at the OBDex `data` directory)")

    rows: list[dict] = []
    skipped = 0
    for family in _FAMILIES:
        f = generic_dir / f"{family}_enriched.yaml"
        if not f.exists():
            print(f"  skipping missing family file: {f.name}")
            continue
        entries = yaml.safe_load(f.read_text(encoding="utf-8")) or []
        for entry in entries:
            if not entry.get("description", {}).get("en"):
                skipped += 1
                continue
            rows.append(to_row(entry, args.max_causes))

    if args.limit > 0:
        rows = rows[: args.limit]

    out = Path(args.output)
    out.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Wrote {len(rows)} codes to {out}")
    if skipped:
        print(f"  skipped {skipped} entries without an English description")


if __name__ == "__main__":
    main()
