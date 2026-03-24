#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./hunt.sh [options] [target]

Options:
  -t, --target TEXT          Target market to hunt (e.g. "Roofers in Ohio")
  -o, --outdir DIR           Output directory (default: current directory)
      --phase NAME           Run a single phase: intel | pitches | calculator | all (default: all)
      --resume               Autopilot resume: skip already-complete phases if output exists
      --status-file FILE     Phase status file path (default: <outdir>/.hunt_status.json)
      --dry-run              Print planned commands without running Gemini/Codex
  -h, --help                 Show this help message

Outputs:
  prey.txt
  pitches.txt
  trojan_horse.html
  .hunt_status.json (phase execution status)
EOF
}

TARGET=""
OUTDIR="$(pwd)"
PHASE="all"
RESUME=0
DRY_RUN=0
STATUS_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)
      TARGET="${2:-}"
      shift 2
      ;;
    -o|--outdir)
      OUTDIR="${2:-}"
      shift 2
      ;;
    --phase)
      PHASE="${2:-}"
      shift 2
      ;;
    --resume)
      RESUME=1
      shift
      ;;
    --status-file)
      STATUS_FILE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
      else
        TARGET+=" $1"
      fi
      shift
      ;;
  esac
done

if [[ -z "${TARGET// }" ]]; then
  echo "Boss, who are we hunting today? (e.g. Roofers in Ohio)"
  read -r TARGET
fi

if [[ -z "${TARGET// }" ]]; then
  echo "No target provided. Exiting." >&2
  exit 1
fi

case "$PHASE" in
  intel|pitches|calculator|all) ;;
  *)
    echo "Invalid --phase value: $PHASE (expected: intel|pitches|calculator|all)" >&2
    exit 1
    ;;
esac

mkdir -p "$OUTDIR"
PREY_FILE="$OUTDIR/prey.txt"
PITCH_FILE="$OUTDIR/pitches.txt"
TROJAN_FILE="$OUTDIR/trojan_horse.html"
STATUS_FILE="${STATUS_FILE:-$OUTDIR/.hunt_status.json}"

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

escape_json() {
  local s="${1:-}"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

write_status() {
  local intel_status="$1"
  local pitches_status="$2"
  local calc_status="$3"
  cat > "$STATUS_FILE" <<EOF
{
  "target": "$(escape_json "$TARGET")",
  "outdir": "$(escape_json "$OUTDIR")",
  "updated_at": "$(now_utc)",
  "phases": {
    "intel": "$intel_status",
    "pitches": "$pitches_status",
    "calculator": "$calc_status"
  }
}
EOF
}

phase_state() {
  local file="$1"
  if [[ -s "$file" ]]; then
    echo "done"
  else
    echo "pending"
  fi
}

run_or_echo() {
  local description="$1"
  shift
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $description"
    return 0
  fi
  "$@"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

run_intel_phase() {
  echo "Deploying The Hound (Gemini)..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run_or_echo "gemini -> $PREY_FILE" true
  else
    gemini "Search the live web for 3 mid-sized $TARGET. Read their websites. Output a brutal 'Prey Profile' detailing their company name, website, and their biggest operational weakness (e.g., no weekend emergency booking). Pure data, no fluff." > "$PREY_FILE"
  fi

  if [[ "$DRY_RUN" -eq 0 && ! -s "$PREY_FILE" ]]; then
    echo "Gemini did not generate prey intelligence. Exiting." >&2
    exit 1
  fi
}

run_pitches_phase() {
  if [[ "$DRY_RUN" -eq 0 && ! -s "$PREY_FILE" ]]; then
    echo "Missing required input for pitches phase: $PREY_FILE" >&2
    exit 1
  fi

  echo "Unleashing The Wolf (Gemini)..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run_or_echo "gemini(prey.txt) -> $PITCH_FILE" true
  else
    gemini "You are the Wolf of Wall Street. Read this intelligence. Write a ruthless, high-status cold email for each target attacking their specific weakness. Tell them how much money they are losing. End with an assumptive Call to Action." < "$PREY_FILE" > "$PITCH_FILE"
  fi

  if [[ "$DRY_RUN" -eq 0 && ! -s "$PITCH_FILE" ]]; then
    echo "Pitches output is empty. Exiting with failure." >&2
    exit 1
  fi
}

run_calculator_phase() {
  if [[ "$DRY_RUN" -eq 0 && ! -s "$PREY_FILE" ]]; then
    echo "Missing required input for calculator phase: $PREY_FILE" >&2
    exit 1
  fi

  echo "Building the Trojan Horse (Codex)..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run_or_echo "codex(prey.txt) -> $TROJAN_FILE" true
  else
    codex exec "Read this intelligence and build a single-file HTML 'Lost Revenue Calculator' tailored to the specific operational weaknesses. Use sleek dark-mode Tailwind CSS. Output strictly the HTML code." < "$PREY_FILE" > "$TROJAN_FILE"
  fi

  if [[ "$DRY_RUN" -eq 0 && ! -s "$TROJAN_FILE" ]]; then
    echo "Trojan horse output is empty. Exiting with failure." >&2
    exit 1
  fi
}

if [[ "$DRY_RUN" -eq 0 ]]; then
  case "$PHASE" in
    intel)
      require_cmd gemini
      ;;
    pitches)
      require_cmd gemini
      ;;
    calculator)
      require_cmd codex
      ;;
    all)
      require_cmd gemini
      require_cmd codex
      ;;
  esac
fi

intel_status="$(phase_state "$PREY_FILE")"
pitches_status="$(phase_state "$PITCH_FILE")"
calc_status="$(phase_state "$TROJAN_FILE")"
write_status "$intel_status" "$pitches_status" "$calc_status"

should_skip() {
  local phase_name="$1"
  local output_file="$2"
  if [[ "$RESUME" -eq 1 && -s "$output_file" ]]; then
    echo "[resume] Skipping $phase_name (already complete: $output_file)"
    return 0
  fi
  return 1
}

run_selected_phases() {
  case "$PHASE" in
    intel)
      if ! should_skip "intel" "$PREY_FILE"; then
        run_intel_phase
      fi
      ;;
    pitches)
      if ! should_skip "pitches" "$PITCH_FILE"; then
        run_pitches_phase
      fi
      ;;
    calculator)
      if ! should_skip "calculator" "$TROJAN_FILE"; then
        run_calculator_phase
      fi
      ;;
    all)
      if ! should_skip "intel" "$PREY_FILE"; then
        run_intel_phase
      fi
      if ! should_skip "pitches" "$PITCH_FILE"; then
        run_pitches_phase
      fi
      if ! should_skip "calculator" "$TROJAN_FILE"; then
        run_calculator_phase
      fi
      ;;
  esac
}

run_selected_phases

intel_status="$(phase_state "$PREY_FILE")"
pitches_status="$(phase_state "$PITCH_FILE")"
calc_status="$(phase_state "$TROJAN_FILE")"
write_status "$intel_status" "$pitches_status" "$calc_status"

if [[ "$PHASE" == "all" && "$DRY_RUN" -eq 0 ]]; then
  if [[ ! -s "$PITCH_FILE" || ! -s "$TROJAN_FILE" ]]; then
    echo "One or more output files are empty. Exiting with failure." >&2
    exit 1
  fi
fi

echo "Hunt execution complete. Generated/updated:"
echo "- $PREY_FILE"
echo "- $PITCH_FILE"
echo "- $TROJAN_FILE"
echo "- $STATUS_FILE"