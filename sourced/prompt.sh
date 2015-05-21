# This contains everything that's done when a Bash prompt happens,
# namely setting: history behaviour, PROMPT_COMMAND, PS1, and PS2.


## Environment variables for controlling Bash history

# History file control to go with fancy PROMPT_COMMAND stuff
export HISTFILE="$HOME/.bash.d/emptyhistory" # Yes, it really is empty.
export HISTARCHIVE="$HOME/.bash.d/history" # Where the "hist" command looks...

# What to store and how
export HISTCONTROL="ignoreboth" # "both" = duplicate commands and whitespace
shopt -s histappend # Append history entries
shopt -s cmdhist # Store multiline commands as single commands


# Set PROMPT_COMMAND.
pcmd() {
	local append="history -a"
	local read="history -n"
	local save="cat $HISTFILE >> \"${HISTARCHIVE}/\$(date --utc +%F)\""
	local zero="> $HISTFILE"
	echo -n "$append;$read;$save;$zero"
}
export PROMPT_COMMAND="$(pcmd)"
unset pcmd

# Set PS1.
ps1() {
	local brown="\[\e[0;33m\]"
	local hm="\$(date +%H%M)"
	local dark="\[\e[1;30m\]"
	local sec="\$(date +:%S)"
	local off="\[\e[0m\]"
	local dir="\$(pwd)"
	echo -n "$brown$hm$dark$sec$off$dir> "
}
export PS1="$(ps1)"
unset ps1

# Set PS2.
ps2() {
	local cyan="\[\e[0;36m\]"
	local off="\[\e[0m\]"
	echo -n "${cyan}> $off"
}
export PS2="$(ps2)"
unset ps2


# See <ref> for Bash "eternal history" which might be adaptable to
# personal customizations and not losing history entered in one
# terminal when also using another.

# ref: http://www.debian-administration.org/articles/543