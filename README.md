# BoilerRoom

`hunt.sh` is a phased outbound-generation pipeline.

## Autopilot Phase Execution

The script now supports explicit phases and resumable autopilot execution.

### Phases

- `intel` → generates `prey.txt`
- `pitches` → generates `pitches.txt` (requires `prey.txt`)
- `calculator` → generates `trojan_horse.html` (requires `prey.txt`)
- `all` → runs phases in order (default)

### Usage

```bash
./hunt.sh --target "Roofers in Ohio"
./hunt.sh --target "Roofers in Ohio" --phase intel
./hunt.sh --target "Roofers in Ohio" --phase all --resume
./hunt.sh --target "Roofers in Ohio" --dry-run
./hunt.sh --no-prompt --target "Roofers in Ohio" --phase intel
```

### Status Tracking

Each run writes a phase state file at:

- default: `<outdir>/.hunt_status.json`
- override with: `--status-file /path/to/status.json`

Status values are `pending` or `done` per phase based on output file presence.

### Non-interactive mode

Use `--no-prompt` in CI/autopilot contexts to fail fast when `--target` is missing instead of waiting for stdin.

## Requirements

- `gemini` CLI for `intel` and `pitches`
- `codex` CLI for `calculator`
