#!/bin/dash
# curWindowId="$(jq -re ".id" <<<$(yabai -m query --windows --window))"
xx=$(yabai -m query --windows --window)
curWindowId="$(echo $xx | jq -re ".id")"

focusWindow() {
    $(yabai -m window --focus $1) # $1 is the first argument passed in (window id).
}

$(yabai -m window --display prev || yabai -m window --display last)
focusWindow "$curWindowId"