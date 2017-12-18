#!/bin/zsh
# ~/.zshrc
# Set ZSH environment stuff.

# Lines configured by zsh-newuser-install
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=10000000
setopt appendhistory nomatch notify
unsetopt autocd beep extendedglob
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/mark/skami/zdani/chakra/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall


# Custom stuff

# Set PS1
__ps1_show_dir() {
    H="${H-/home/$USER}" # TODO: Remove once it's set globally
    local dir="${PWD/#$H/~}" # Replace leading $H with (uneventfully literal) ~
    local prefix="$dir[1]" # Get first character; either ~ or /
    local repl="…" # Replacement character if it's too long
    local end="${dir: -42}" # TODO: Don't hardcode amount of path to keep
    if [ "${#end}" -lt "$((${#dir}-${#prefix}-${#repl}))" ]; then
        dir="$prefix$repl$end"
    fi
    echo -n "$dir"
}
__ps1_sleep_reminder() {
    for x in 23 0 1 2 3 4; do
        echo -n #"%(${x}T,%B%9FGo to sleep!%F{16}%K{16},)"
    done
}
ps1() {
    # Colors
    local b='%f%B'
    local yellow='%b%F{yellow}'
    local bgray='%B%F{8}'
    local green='%b%F{green}'
    local bred='%B%F{red}'
    local off='%f%k%b%u%s'

    # Time stuff
    local hm='%D{%H%M}'
    local sec='%D{%S}'
    local time="$yellow$hm$bgray:$sec"

    # Nearby directories
    local dir_cmd='$(__ps1_show_dir)'
    local dir="$green$dir_cmd"

    # Status code and "> "
    local root_status='%(!.#.>)'
    local status_code='%(?,,%?!)'
    local status_text="$b$root_status$bred$status_code "

    # Sleep reminder
    local sleep_reminder='$(__ps1_sleep_reminder)'

    # Echo the whole thing
    echo -n "$time$dir$status_text$off$sleep_reminder"

    # Result:
    # %3F%D{%H%M}%8F:%D{%S}%2F%(3/,…/,)%2/%15F%(!.#.>)%9F%(?,,%?!) %f$(__ps1_sleep_reminder)
}
setopt promptsubst
export PS1="$(ps1)"
unset ps1
