"--------------------------------------------------------------------------
"
" Vim script to launch/control browsers
"
" Copyright ????-2009 Christian J. Robinson <heptite@gmail.com>
"
" Distributable under the terms of the GNU GPL.
"
" Currently supported browsers:
" Unix:
"  - Firefox  (remote [new window / new tab] / launch)  [1]
"  - Mozilla  (remote [new window / new tab] / launch)  [1]
"  - Netscape (remote [new window] / launch)            [1]
"  - Opera    (remote [new window / new tab] / launch)
"  - Lynx     (Under the current TTY if not running the GUI, or a new xterm
"              window if DISPLAY is set.)
"  - w3m      (Under the current TTY if not running the GUI, or a new xterm
"              window if DISPLAY is set.)
" MacOS:
"  - Firefox  (remote [new window / new tab] / launch)
"  - Opera    (remote [new window / new tab] / launch)
"  - Safari   (remote [new window / new tab] / launch)
"  - Default
"
" Windows:
"  None currently -- the HTML.vim script has mappings that runs system
"  commands directly.
"
" TODO:
"
"  - Support more browsers?
"    + links  (text browser)
"
"    Note: Various browsers such as galeon, nautilus, phoenix, &c use the
"    same HTML rendering engine as mozilla/firefox, so supporting them
"    isn't as important.
"
"  - Defaulting to lynx if the the GUI isn't available on Unix may be
"    undesirable.
"
"  - Support for Windows.
"
" BUGS:
"  * [1] On Unix, the remote control for firefox/mozilla/netscape will
"    probably default to firefox if more than one is running.
"
"  * On Unix, Since the commands to start the browsers are run in the
"    backgorund when possible there's no way to actually get v:shell_error,
"    so execution errors aren't actually seen when not issuing a command to
"    an already running browser.
"
"  * The code is a mess and mostly needs to be rethought.  Oh well.
"
"--------------------------------------------------------------------------

if v:version < 700
	finish
endif

command! -nargs=+ BERROR :echohl ErrorMsg | echomsg <q-args> | echohl None
command! -nargs=+ BMESG :echohl Todo | echo <q-args> | echohl None

function! s:ShellEscape(str) " {{{
	if exists('*shellescape')
		return shellescape(a:str)
	else
		return "'" . substitute(a:str, "'", "'\\\\''", 'g') . "'"
	endif
endfunction " }}}


if has('mac') || has('macunix')  " {{{1

	"BERROR Currently there's no browser control support for Macintosh.
	"BERROR See ":help html-author-notes"


	" The following code is provided by Israel Chauca Fuentes
	" <israelvarios()fastmail!fm>:

	function! s:MacAppExists(app) " {{{
		 silent! call system("/usr/bin/osascript -e 'get id of application \"" .
				\ a:app . "\"' 2>&1 >/dev/null")
		if v:shell_error
			return 0
		endif
		return 1
	endfunction " }}}

	function! s:UseAppleScript() " {{{
		return system("/usr/bin/osascript -e " .
			 \ "'tell application \"System Events\" to set UI_enabled " .
			 \ "to UI elements enabled' 2>/dev/null") ==? "true\n" ? 1 : 0
	endfunction " }}}

	function! OpenInMacApp(app, ...) " {{{
		if (! s:MacAppExists(a:app) && a:app !=? 'default')
			exec 'BERROR ' . a:app . " not found."
			return 0
		endif

		if a:0 >= 1 && a:0 <= 2
			let new = a:1
		else
			let new = 0
		endif

		let file = expand('%:p')

		" Can we open new tabs and windows?
		let use_AS = s:UseAppleScript()

		" Why we can't open new tabs and windows:
		let as_msg = "This feature utilizes the built-in Graphic User " .
				\ "Interface Scripting architecture of Mac OS X which is " .
				\ "currently disabled. You can activate GUI Scripting by " .
				\ "selecting the checkbox \"Enable access for assistive " .
				\ "devices\" in the Universal Access preference pane."

		if (a:app ==? 'safari') " {{{
			if new != 0 && use_AS
				if new == 2
					let torn = 't'
					BMESG Opening file in new Safari tab...
				else
					let torn = 'n'
					BMESG Opening file in new Safari window...
				endif
				let script = '-e "tell application \"safari\"" ' .
				\ '-e "activate" ' .
				\ '-e "tell application \"System Events\"" ' .
				\ '-e "tell process \"safari\"" ' .
				\ '-e "keystroke \"' . torn . '\" using {command down}" ' .
				\ '-e "end tell" ' .
				\ '-e "end tell" ' .
				\ '-e "delay 0.3" ' .
				\ '-e "tell window 1" ' .
				\ '-e ' . s:ShellEscape("set (URL of last tab) to \"" . file . "\"") . ' ' .
				\ '-e "end tell" ' .
				\ '-e "end tell" '

				let command = "/usr/bin/osascript " . script

			else
				if new != 0
					" Let the user know what's going on:
					exec 'BERROR ' . as_msg
				endif
				BMESG Opening file in Safari...
				let command = "/usr/bin/open -a safari " . s:ShellEscape(file)
			endif
		endif "}}}

		if (a:app ==? 'firefox') " {{{
			if new != 0 && use_AS
				if new == 2

					let torn = 't'
					BMESG Opening file in new Firefox tab...
				else

					let torn = 'n'
					BMESG Opening file in new Firefox window...
				endif
				let script = '-e "tell application \"firefox\"" ' .
				\ '-e "activate" ' .
				\ '-e "tell application \"System Events\"" ' .
				\ '-e "tell process \"firefox\"" ' .
				\ '-e "keystroke \"' . torn . '\" using {command down}" ' .
				\ '-e "delay 0.8" ' .
				\ '-e "keystroke \"l\" using {command down}" ' .
				\ '-e "keystroke \"a\" using {command down}" ' .
				\ '-e ' . s:ShellEscape("keystroke \"" . file . "\" & return") . " " .
				\ '-e "end tell" ' .
				\ '-e "end tell" ' .
				\ '-e "end tell" '

				let command = "/usr/bin/osascript " . script

			else
				if new != 0
					" Let the user know wath's going on:
					exec 'BERROR ' . as_msg

				endif
				BMESG Opening file in Firefox...
				let command = "/usr/bin/open -a firefox " . s:ShellEscape(file)
			endif
		endif " }}}

		if (a:app ==? 'opera') " {{{
			if new != 0 && use_AS
				if new == 2

					let torn = 't'
					BMESG Opening file in new Opera tab...
				else

					let torn = 'n'
					BMESG Opening file in new Opera window...
				endif
				let script = '-e "tell application \"Opera\"" ' .
				\ '-e "activate" ' .
				\ '-e "tell application \"System Events\"" ' .
				\ '-e "tell process \"opera\"" ' .
				\ '-e "keystroke \"' . torn . '\" using {command down}" ' .
				\ '-e "end tell" ' .
				\ '-e "end tell" ' .
				\ '-e "delay 0.5" ' .
				\ '-e ' . s:ShellEscape("set URL of front document to \"" . file . "\"") . " " .
				\ '-e "end tell" '

				let command = "/usr/bin/osascript " . script

			else
				if new != 0
					" Let the user know what's going on:
					exec 'BERROR ' . as_msg

				endif
				BMESG Opening file in Opera...
				let command = "/usr/bin/open -a opera " . s:ShellEscape(file)
			endif
		endif " }}}

		if (a:app ==? 'default')

			BMESG Opening file in default browser...
			let command = "/usr/bin/open " . s:ShellEscape(file)
		endif

		if (! exists('command'))

			exe 'BMESG Opening ' . substitute(a:app, '^.', '\U&', '') . '...'
			let command = "open -a " . a:app . " " . s:ShellEscape(file)
		endif

		call system(command . " 2>&1 >/dev/null")
	endfunction " }}}

elseif has('unix') " {{{1

	let s:Browsers = {}
	let s:BrowsersExist = 'fmnolw'

	let s:Browsers['f'] = ['firefox',  0]
	let s:Browsers['m'] = ['mozilla',  0]
	let s:Browsers['n'] = ['netscape', 0]
	let s:Browsers['o'] = ['opera',    0]
	let s:Browsers['l'] = ['lynx',     0]
	let s:Browsers['w'] = ['w3m',      0]

	for s:temp1 in keys(s:Browsers)
		let s:temp2 = system("which " . s:Browsers[s:temp1][0])
		if v:shell_error == 0
			let s:Browsers[s:temp1][1] = substitute(s:temp2, "\n$", '', '')
		else
			let s:BrowsersExist = substitute(s:BrowsersExist, s:temp1, '', 'g')
		endif
	endfor

	unlet s:temp1 s:temp2

	let s:NetscapeRemoteCmd = substitute(system("which mozilla-xremote-client"), "\n$", '', '')
	if v:shell_error != 0
		let s:NetscapeRemoteCmd = substitute(system("which netscape-remote"), "\n$", '', '')
	endif
	if v:shell_error != 0
		if s:Browsers['f'][1] != 0
			let s:NetscapeRemoteCmd = s:Browsers['f'][1]
		elseif s:Browsers['m'][1] != 0
			let s:NetscapeRemoteCmd = s:Browsers['m'][1]
		elseif s:Browsers['n'][1] != 0
			let s:NetscapeRemoteCmd = s:Browsers['n'][1]
		else
			"BERROR Can't set up remote-control preview code.
			"BERROR (netscape-remote/firefox/mozilla/netscape not installed?)
			"finish
			let s:NetscapeRemoteCmd = 'false'
		endif
	endif

elseif has('win32') || has('win64')  " {{{1

	BERROR Currently there's no browser control support for Windows.
	BERROR See ":help html-author-notes"
	
	"let s:Browsers = {}
	"let s:BrowsersExist = ''

	"if filereadable('C:\Program Files\Mozilla Firefox\firefox.exe')
	"	let s:Browsers['f'] = ['firefox', '"C:\Program Files\Mozilla Firefox\firefox.exe"']
	"	let s:BrowsersExist .= 'f'
	"endif

	"if s:Browsers['f'][1] != ''
	"	let s:NetscapeRemoteCmd = s:Browsers['f'][1]
	"endif

endif " }}}1


if exists("*LaunchBrowser") || exists("*OpenInMacApp")
	finish
endif

" LaunchBrowser() {{{1
"
" Usage:
"  :call LaunchBrowser({[nolmf]},{[012]},[url])
"    The first argument is which browser to launch:
"      f - Firefox
"      m - Mozilla
"      n - Netscape
"      o - Opera
"      l - Lynx
"      w - w3m
"
"      default - This launches the first browser that was actually found.
"
"    The second argument is whether to launch a new window:
"      0 - No
"      1 - Yes
"      2 - New Tab (or new window if the browser doesn't provide a way to
"                   open a new tab)
"
"    The optional third argument is an URL to go to instead of loading the
"    current file.
"
" Return value:
"  0 - Failure (No browser was launched/controlled.)
"  1 - Success
"
" A special case of no arguments returns a character list of what browsers
" were found.
function! LaunchBrowser(...)

	let err = 0

	if a:0 == 0
		return s:BrowsersExist
	elseif a:0 >= 2
		let which = a:1
		let new = a:2
	else
		let err = 1
	endif

	let file = 'file://' . expand('%:p')

	if a:0 == 3
		let file = a:3
	elseif a:0 > 3
		let err = 1
	endif

	if err
		exe 'BERROR E119: Wrong number of arguments for function: '
					\ . substitute(expand('<sfile>'), '^function ', '', '')
		return 0
	endif

	if which ==? 'default'
		let which = strpart(s:BrowsersExist, 0, 1)
	endif

	if s:BrowsersExist !~? which
		if exists('s:Browsers[which]')
			exe 'BERROR ' . s:Browsers[which][0] . ' not found'
		else
			exe 'BERROR Unknown browser ID: ' . which
		endif

		return 0
	endif

	if has('unix') && (! strlen($DISPLAY) || which ==? 'l') " {{{
		BMESG Launching lynx...

		if (has("gui_running") || new) && strlen($DISPLAY)
			let command='xterm -T Lynx -e lynx ' . s:ShellEscape(file) . ' &'
		else
			sleep 1
			execute "!lynx " . s:ShellEscape(file)

			if v:shell_error
				BERROR Unable to launch lynx.
				return 0
			endif
		endif
	endif " }}}

	if (which ==? 'w') " {{{
		BMESG Launching w3m...

		if (has("gui_running") || new) && strlen($DISPLAY)
			let command='xterm -T w3m -e w3m ' . s:ShellEscape(file) . ' &'
		else
			sleep 1
			execute "!w3m " . s:ShellEscape(file)

			if v:shell_error
				BERROR Unable to launch w3m.
				return 0
			endif
		endif
	endif " }}}

	if (which ==? 'o') " {{{
		if new == 2
			BMESG Opening new Opera tab...
			let command="sh -c \"trap '' HUP; " . s:Browsers[which][1] . " -remote 'openURL('" . s:ShellEscape(file) . "',new-page)' &\""
		elseif new
			BMESG Opening new Opera window...
			let command="sh -c \"trap '' HUP; " . s:Browsers[which][1] . " -remote 'openURL('" . s:ShellEscape(file) . "',new-window)' &\""
		else
			BMESG Sending remote command to Opera...
			let command="sh -c \"trap '' HUP; " . s:Browsers[which][1] . " " . s:ShellEscape(file) . " &\""
		endif
	endif " }}}

	" Find running instances firefox/mozilla/netscape:  {{{
	if has('unix')
		let FirefoxRunning = 0
		let MozillaRunning = 0
		let NetscapeRunning = 0

		let windows = system("xwininfo -root -children | egrep \"[Ff]irefox|[Nn]etscape|[Mm]ozilla\"; return 0")

		if windows =~? 'firefox'
			let FirefoxRunning = 1
		endif
		if windows =~? 'mozilla'
			let MozillaRunning = 1
		endif
		if windows =~? 'netscape'
			let NetscapeRunning = 1
		endif
	else
		" ... Make some assumptions:
		"let FirefoxRunning = 1
	endif  " }}}

	if (which ==? 'f') " {{{
		if ! FirefoxRunning
			BMESG Launching firefox, please wait...
			let command="sh -c \"trap '' HUP; " . s:Browsers[which][1] . " " . s:ShellEscape(file) . " &\""
		else
			if new == 2
				BMESG Opening new Firefox tab...
				let command=s:NetscapeRemoteCmd . " -remote 'openURL('" . s:ShellEscape(file) . "',new-tab)'"
			elseif new
				BMESG Opening new Firefox window...
				let command=s:NetscapeRemoteCmd . " -remote 'openURL('" . s:ShellEscape(file) . "',new-window)'"
			else
				BMESG Sending remote command to Firefox...
				let command=s:NetscapeRemoteCmd . " -remote 'openURL('" . s:ShellEscape(file) . "')'"
			endif
		endif
	endif " }}}

	if (which ==? 'm') " {{{
		if ! MozillaRunning
			BMESG Launching mozilla, please wait...
			let command="sh -c \"trap '' HUP; " . s:Browsers[which][1] . " " . s:ShellEscape(file) . " &\""
		else
			if new == 2
				BMESG Opening new Mozilla tab...
				let command=s:NetscapeRemoteCmd . " -remote 'openURL('" . s:ShellEscape(file) . "',new-tab)'"
			elseif new
				BMESG Opening new Mozilla window...
				let command=s:NetscapeRemoteCmd . " -remote 'openURL('" . s:ShellEscape(file) . "',new-window)'"
			else
				BMESG Sending remote command to Mozilla...
				let command=s:NetscapeRemoteCmd . " -remote 'openURL('" . s:ShellEscape(file) . "')'"
			endif
		endif
	endif " }}}

	if (which ==? 'n') " {{{
		if ! NetscapeRunning
			BMESG Launching netscape, please wait...
			let command="sh -c \"trap '' HUP; " . s:Browsers[which][1] . " " . s:ShellEscape(file) . " &\""
		else
			if new
				BMESG Opening new Netscape window...
				let command=s:NetscapeRemoteCmd . " -remote 'openURL('" . s:ShellEscape(file) . "',new-window)'"
			else
				BMESG Sending remote command to Netscape...
				let command=s:NetscapeRemoteCmd . " -remote 'openURL('" . s:ShellEscape(file) . "')'"
			endif
		endif
	endif " }}}

	if exists('l:command')

		if command =~ 'mozilla-xremote-client'
			let command = substitute(command, '-remote', '-a ' . s:Browsers[which][0], '')
		endif

		if ! has('unix')
			let command = substitute(command, "sh -c \"trap '' HUP; \\(.\\+\\) &\"", '\1', '')
			let command = substitute(command, '"\(openURL(.\+)\)"', '\1', '')
		endif

		call system(command)

		if has('unix') && v:shell_error
			exe 'BERROR Command failed: ' . command
			return 0
		endif

		return 1
	endif

	" Should never get here...if we do, something went wrong:
	BERROR Something went wrong, shouln't ever get here...
	return 0
endfunction " }}}1

" vim: set ts=2 sw=2 ai nu tw=75 fo=croq2 fdm=marker fdc=4:
