#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./hunt.sh [options] [target]

Options:
  -t, --target TEXT   Target market to hunt (e.g. "Roofers in Ohio")
  -o, --outdir DIR    Output directory (default: current directory)
  -h, --help          Show this help message

Outputs:
  prey.txt
  pitches.txt
  trojan_horse.html
EOF
}

TARGET=""
OUTDIR="$(pwd)"

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

for cmd in gemini codex; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

mkdir -p "$OUTDIR"
PREY_FILE="$OUTDIR/prey.txt"
PITCH_FILE="$OUTDIR/pitches.txt"
TROJAN_FILE="$OUTDIR/trojan_horse.html"

echo "Deploying The Hound (Gemini)..."
gemini "Search the live web for 3 mid-sized $TARGET. Read their websites. Output a brutal 'Prey Profile' detailing their company name, website, and their biggest operational weakness (e.g., no weekend emergency booking). Pure data, no fluff." > "$PREY_FILE"

if [[ ! -s "$PREY_FILE" ]]; then
  echo "Gemini did not generate prey intelligence. Exiting." >&2
  exit 1
fi

echo "Unleashing The Wolf (Gemini)..."
gemini "You are the Wolf of Wall Street. Read this intelligence. Write a ruthless, high-status cold email for each target attacking their specific weakness. Tell them how much money they are losing. End with an assumptive Call to Action." < "$PREY_FILE" > "$PITCH_FILE"

echo "Building the Trojan Horse (Codex)..."
codex exec "Read this intelligence and build a single-file HTML 'Lost Revenue Calculator' tailored to the specific operational weaknesses. Use sleek dark-mode Tailwind CSS. Output strictly the HTML code." < "$PREY_FILE" > "$TROJAN_FILE"

if [[ ! -s "$PITCH_FILE" || ! -s "$TROJAN_FILE" ]]; then
  echo "One or more output files are empty. Exiting with failure." >&2
  exit 1
fi

echo "The hunt is done. Generated:"
echo "- $PREY_FILE"
echo "- $PITCH_FILE"
echo "- $TROJAN_FILE"
