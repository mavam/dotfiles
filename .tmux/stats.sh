#!/bin/sh

stats=""
if [ "$OS" == "linux-gnu" ]; then
  stats=$(top -b -n 1 | head -n 5)
elif [ "$OS" == "darwin" ]; then
  stats=$(top -R -F -l 1 | head -n 9)
elif [ "$OS" == "freebsd" ]; then
  stats=$(top -I -b | head -n 5)
fi

printf %s "$stats" | awk -v ORS="" -v sep=" ● " -f ~/.tmux/stats-$OS.awk
