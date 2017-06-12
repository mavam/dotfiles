#! /bin/sh -
# require a POSIX sh, on those systems where the POSIX sh is not in /bin
# (like Solaris), you may need to adapt the shebang line above
# (/usr/xpg4/bin/sh on Solaris). You also need a terminfo aware "tput",
# ncurses one (the default on most systems) will do.

# wrapper around mairix, the mail indexing/searching utility for mutt.
# in your ~/.muttrc:
# macro generic S "<enter-command>set my_cmd = \`mutt-mairix\`<return><enter-command>push \$my_cmd<return>"
# we're not using <shell-escape> because we want to prompt the user in
# mutt's prompt area and still have mutt's index visible.

# mairix result folder in mutt folder syntax:
mfolder=$HOME/.mairix/search

# disable globbing.
set -f

# restore stdin/stdout to the terminal, fd 3 goes to mutt's backticks.
exec < /dev/tty 3>&1 > /dev/tty

# save tty settings before modifying them
saved_tty_settings=$(stty -g)

# upon SIGINT (mapped to <Ctrl-G> below instead of <Ctrl-C> to match
# mutt behavior), cancel the action.
trap '
    printf "\r"; tput ed; tput rc
    printf "<return>" >&3
    stty "$saved_tty_settings"
    exit
' INT TERM

cmd=

# put the terminal in cooked mode. Set eof to <Return> so that pressing
# <Return> doesn't move the cursor to the next line. Disable <Ctrl-Z>
stty icanon echo -ctlecho eof '^M' intr '^G' susp '' 2> /dev/null

# retrieve the size of the screen.
set $(stty size)

# save cursor position:
tput sc

# go to last line of the screen
tput cup "$1" 0

# Clear and write prompt.
tput ed
printf 'Pattern: '

# read from the terminal. We can't use "read" because, there won't be
# any NL in the input as <Return> is eof.
search=$(dd count=1 2> /dev/null)

case $search in
  ("")
    # rebuild the index
    mairix -F > /dev/null
    ;;
  (+*)
    # append mode
    mairix -a ${search#+} > /dev/null
    cmd="<change-folder-readonly>$mfolder<return>"
    ;;
  (*)
    mairix $search > /dev/null
    cmd="<change-folder-readonly>$mfolder<return>"
    ;;
esac

# clear our mess
printf '\r'; tput ed

# restore cursor position
tput rc

# and tty settings
stty "$saved_tty_settings"

printf %s "$cmd" >&3
