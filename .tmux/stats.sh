#!/bin/sh

stats=""
if [ "$OS" == "linux-gnu" ]; then
  stats=$(top -b -n 1 | head -n 5)
elif [ "$OS" == "darwin" ]; then
  stats=$(top -R -F -l 1 | head -n 9)
fi

printf %s "$stats" | awk -f ~/.tmux/stats-$OS.awk
