#!/bin/zsh

LOG_FILE="$HOME/track_build_metrics.txt"
SUMMARY_DIR="$HOME/summaries"
mkdir -p "$SUMMARY_DIR"
SUMMARY_FILE="$SUMMARY_DIR/build_summary_$(date +%Y-%m-%d).txt"

if [[ ! -f "$LOG_FILE" ]] || [[ $(wc -l < "$LOG_FILE") -le 2 ]]; then
    echo "📭 No metrics found to summarize."
    exit 0
fi

cp "$LOG_FILE" "$SUMMARY_FILE"

echo "TIMESTAMP           | COMMAND                        | STATUS  | DURATION" > "$LOG_FILE"
echo "--------------------------------------------------------------------------" >> "$LOG_FILE"

echo "✅ Summary created: $SUMMARY_FILE"
echo "🧹 $LOG_FILE has been cleared."