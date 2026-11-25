# Fine-tuning AutoIntel's LLM (OpenAI)

This directory turns your diagnostic data into an OpenAI fine-tune that speaks
AutoIntel's exact language, and swaps the result into the running app.

## Why fine-tune?

Fine-tuning teaches the model AutoIntel's **tone and JSON shape**, so every
explanation comes back as `{"plain_explanation", "likely_causes", "severity",
"recommended_action"}` — no markdown fences, no stray prose, no made-up fields.

It does **not** by itself stop hallucination. For factual accuracy, the training
data must be correct, and for the hard cases you should still ground the model
with a knowledge base (RAG). The app's `ai_service.dart` already has a small
version of this; a fine-tune plus that knowledge base is the strongest combo.

## Dataset source (OBDex)

The full training set is generated from [OBDex](https://github.com/foerbsnavi/OBDex),
the complete machine-readable list of all 9,533 generic OBD-II codes. Clone it and
convert it:

```bash
git clone --depth 1 https://github.com/foerbsnavi/OBDex C:\obdex
venv\Scripts\python -m finetune.build_obdex_dataset --obdex-dir C:\obdex\data -o finetune\obdex_rows.json
venv\Scripts\python -m finetune.prepare_data finetune\obdex_rows.json -o finetune\finetune.jsonl
```

`build_obdex_dataset.py` maps OBDex's `description`/`common_causes`/`repair`/`flags`
into AutoIntel's fields, deriving `severity` (limp-mode + repair difficulty) and a
`recommended_action`. Severity comes out roughly balanced: ~40% medium, ~31% high,
~20% critical, ~8% low. Tweak `derive_severity`/`derive_action` if you want different
thresholds.

## Data format

Feed `prepare_data.py` a JSON file (array of objects) or a CSV. Required fields:

| Field                 | Meaning                                          |
|-----------------------|--------------------------------------------------|
| `code`                | OBD-II code, e.g. `P0301`                        |
| `plain_explanation`   | 2-3 plain-English sentences                      |
| `severity`            | `low` \| `medium` \| `high` \| `critical`        |

Optional fields:

| Field                  | Meaning                                   |
|------------------------|-------------------------------------------|
| `likely_causes`        | list (JSON) or comma-separated string     |
| `recommended_action`   | what the driver should do next            |
| `raw_description`      | SAE standard description (rarely needed)  |

`seed_codes.json` shows the exact shape. Add your own examples to it (or a new
file) — aim for **at least 50-100** examples, ideally a few hundred, covering
the codes you actually expect to see.

## Run it

From `backend/`, with the venv active:

```bash
# 1. Convert your data to OpenAI JSONL
venv\Scripts\python -m finetune.prepare_data finetune\seed_codes.json -o finetune\finetune.jsonl

# 2. Set OPENAI_API_KEY in backend/.env, then launch the fine-tune
venv\Scripts\python -m finetune.run_finetune finetune\finetune.jsonl

# (optional) monitor an in-flight job
venv\Scripts\python -m finetune.run_finetune --resume ftjob-xxxxxxxx
```

When the job succeeds, the script prints a `ft:gpt-4o-mini-...` model id. Put it
in `backend/.env`:

```
OPENAI_MODEL=ft:gpt-4o-mini-xxxx:autointel:xxxxxxxx
```

and restart the backend. The `ai/llm_client.py` already reads `OPENAI_MODEL`, so
no code changes are needed to switch models.
