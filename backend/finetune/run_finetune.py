"""Upload a fine-tuning JSONL and launch/monitor an OpenAI fine-tuning job.

Usage (from backend/, with the venv active and OPENAI_API_KEY set in .env):

    python -m finetune.run_finetune finetune/finetune.jsonl
    python -m finetune.run_finetune --resume ftjob-xxxxxxxx   # monitor an existing job
"""

import argparse
import sys
import time
from pathlib import Path

# Make `utils` importable whether run as a script or `python -m`.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from openai import OpenAI  # noqa: E402

from utils.config import settings  # noqa: E402


def monitor(client: OpenAI, job_id: str):
    while True:
        status = client.fine_tuning.jobs.retrieve(job_id)
        print(f"  status: {status.status}", flush=True)
        if status.status in ("succeeded", "failed", "cancelled"):
            return status
        time.sleep(60)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("jsonl", nargs="?", help="path to the training JSONL")
    ap.add_argument("--model", default="gpt-4o-mini-2024-07-18",
                    help="base model to fine-tune (default: gpt-4o-mini-2024-07-18)")
    ap.add_argument("--suffix", default="autointel",
                    help="suffix for the fine-tuned model name")
    ap.add_argument("--resume", metavar="JOB_ID",
                    help="monitor an existing job instead of creating a new one")
    args = ap.parse_args()

    if not settings.openai_api_key or settings.openai_api_key == "your_openai_key_here":
        raise SystemExit("OPENAI_API_KEY is not set in backend/.env")

    client = OpenAI(api_key=settings.openai_api_key)

    if args.resume:
        status = monitor(client, args.resume)
    else:
        if not args.jsonl:
            raise SystemExit("pass a JSONL file (or use --resume <job_id>)")

        print("Uploading training file...")
        with open(args.jsonl, "rb") as f:
            file = client.files.create(file=f, purpose="fine-tune")
        print(f"  file id: {file.id}")

        print("Creating fine-tuning job...")
        job = client.fine_tuning.jobs.create(
            training_file=file.id,
            model=args.model,
            suffix=args.suffix,
        )
        print(f"  job id: {job.id}")
        status = monitor(client, job.id)

    if status.status == "succeeded":
        print(f"\nFine-tuned model id: {status.fine_tuned_model}")
        print("Set OPENAI_MODEL=<that id> in backend/.env to use it in AutoIntel.")
    else:
        print(f"\nJob ended with status: {status.status}")


if __name__ == "__main__":
    main()
