#! /usr/bin/env sh

# make this file executable using:
#     chmod +x /path/to/this/script
# create a signal using: 
#     yabai -m signal --add event=window_created action="/path/to/this/script"

# get the window id of the newly created window
wid="${2}"

# if the split is horizontal, toggle it to vertical
# yabai -m query --windows --window "${wid}" --stack weast | jq -re '.split == "horizontal"' \
#    && yabai -m window ${wid} --stack $(yabai -m query --windows --window | jq -r '.id')
# yabai -m query --windows --window "${wid}" --stack ${wid} | jq -re '.split == "horizontal"' \
    #  && yabai -m window "${wid}" --toggle split
# yabai -m window "${wid}" --stack "${wid}" || (yabai -m window ${wid} --toggle float && yabai -m window ${wid} --toggle float)
# yabai -m window weast --stack $(yabai -m query --windows --window | jq -r '.id')
#  yabai -m window north --stack $(yabai -m query --windows --window | jq -r '.id') && echo $wid && echo $(yabai -m query --windows --window | jq -r '.id')