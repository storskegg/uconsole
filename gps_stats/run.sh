#!/bin/bash

PATH_STATS=/var/log/chrony/statistics.log

echo "You'll want to have let the GPS run for at least 1 hour or more. If you haven't"
echo "done that yet, there won't be enough statistics to process."
echo ""
read -p "Press Enter to continue, or Ctrl+C to abort."

[[ -f "$PATH_STATS" ]] || { echo "Statistics log not found at $PATH_STATS"; exit 1; }

tail -100 "$PATH_STATS" > ./chrony_statistics.log

NUM_LINES=$(wc -l ./chrony_statistics.log | awk '{print $1}')
[[ $NUM_LINES -lt 100 ]] && { echo "Not enough statistics in the log. Wait longer."; exit 1; }

python3 ./est_offset.py

