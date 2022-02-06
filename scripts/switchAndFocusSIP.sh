# #!/bin/dash

# By me.. Jesse. Sorry in advance.
# I press the Hyper key + 1-3 for switching spaces. Hyper + 1 will switch between spaces 1 & 2 for example.
# This script will make it so I *never lose focus on applications while switching spaces.
# If I have focus of window on display 1 and change spaces on display 2, i'll keep focus on display 1.
# If I have focus of window on display 1 and change spces on display 1, I'll check to see if there is any windows to focus on on display 1's next space, if there IS, i'll move foucs to it, else I'll move focus to any VISIBLE window on display's 2 or 3 in order to keep SOMETHING focused. If there is no visible windows on the new space or displays 2 and 3, Nothing will take focus, which is fine.
# If I have NOTHING focused and I change spaces, try to focus on ANY visible window on the new space. Else, try to focus on any visibe window on any visible space.
# the end.

# I call this script like this in skhd >> hyper - 3 : /path/to/thisScript.sh 3

inputKeyNumber=$1 # input argument : 1 - 3

CurrentlyFocusedWindow=$(yabai -m query --windows --window | jq -re ".")

CurrentlyFocusedWindowID=$(echo $CurrentlyFocusedWindow | jq -re ".id")

CurrentlyFocusedDisplay=$(echo $CurrentlyFocusedWindow | jq -re ".display")

CurrentlyVisibleSpaceNames=$(yabai -m query --spaces | jq -re ".[] | select(.visible == 1)" | jq -re ".label")

# my custom space names in yabairc:
#  yabai -m space 1 --label one
#  yabai -m space 2 --label two
#  yabai -m space 3 --label three
#  yabai -m space 4 --label four
#  yabai -m space 5 --label five
#  yabai -m space 6 --label six
case $inputKeyNumber in
'1')
    firstSpaceName='one'
    firstspacenumber='1'
    secondSpaceName='two'
    secondSpacenumber='2'
    firstSpaceName='three'
    firstspacenumber='3'
    ;;
'2')
    firstSpaceName='four'
    firstspacenumber='4'
    secondSpaceName='five'
    secondSpacenumber='5'
    firstSpaceName='six'
    firstspacenumber='6'
    ;;
esac

focusWindow() {                   # function
    sleep .3                      # Sip Enabled, waiting for stupid spaces animation to finish
    $(yabai -m window --focus $1) # $1 is the first argument passed in (window id).
}

focusDisplay() {                   # function
    sleep .3                       # Sip Enabled, waiting for stupid spaces animation to finish
    $(yabai -m display --focus $1) # $1 is the first argument passed in (window id).
}

TryFocusOnSpaceWereGoingToElseFocusOnAnyVisibleWindow() { # function
    # $1 space NAME we're going to
    # $2 space NUMBER we're going to 1-6
    # $3 space Name coming FROM
    # $4 space Number coming FROM 1-6
    windowOnNextSpace=$(yabai -m query --spaces --space $1 | jq -re '.["first-window"]') # is there an app on next space?
    if [[ "$windowOnNextSpace" -ne "0" ]]; then
        $(skhd -k "ctrl + alt + cmd - $2")
        focusWindow "$windowOnNextSpace"
    else # no app on new space
        newWindowToFocusIfPossible=$(yabai -m query --windows | jq -re ".[] | select((.visible == 1) and .space != $4).id" | head -n 1)
        if [[ -n "$newWindowToFocusIfPossible" ]]; then
            $(skhd -k "ctrl + alt + cmd - $2")
            focusWindow $newWindowToFocusIfPossible
        else
            $(skhd -k "ctrl + alt + cmd - $2")
        fi
    fi
}

if [[ $CurrentlyVisibleSpaceNames == *$firstSpaceName* ]]; then
    if [ -n ${CurrentlyFocusedWindowID} ]; then # (-n) >> != null
        if [ $CurrentlyFocusedDisplay -ne $inputKeyNumber ]; then
            $(skhd -k "ctrl + alt + cmd - $secondSpacenumber") # shortcut for changing spaces with SIP Enabled
            focusWindow $CurrentlyFocusedWindowID
        else
            TryFocusOnSpaceWereGoingToElseFocusOnAnyVisibleWindow $secondSpaceName $secondSpacenumber $firstSpaceName $firstspacenumber
        fi
    else
        TryFocusOnSpaceWereGoingToElseFocusOnAnyVisibleWindow $secondSpaceName $secondSpacenumber $firstSpaceName $firstspacenumber
    fi
elif [[ $CurrentlyVisibleSpaceNames == *$secondSpaceName* ]]; then
    if [ -n ${CurrentlyFocusedWindowID} ]; then # (-n) >> != null
        if [ $CurrentlyFocusedDisplay -ne $inputKeyNumber ]; then
            $(skhd -k "ctrl + alt + cmd - $firstspacenumber") # shortcut for changing spaces with SIP Enabled
            focusWindow $CurrentlyFocusedWindowID
        else
            TryFocusOnSpaceWereGoingToElseFocusOnAnyVisibleWindow $firstSpaceName $firstspacenumber $secondSpaceName $secondSpacenumber
        fi
    else
        TryFocusOnSpaceWereGoingToElseFocusOnAnyVisibleWindow $firstSpaceName $firstspacenumber $secondSpaceName $secondSpacenumber
    fi
fi