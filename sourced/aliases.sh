# Prettiness
alias ls='ls --group-directories-first --time-style=+"%Y-%m-%d_%H%M:%S" --color=auto'
alias df='df -h'
alias free='free -m'
alias grep='grep --color=tty'
alias fgrep='fgrep --color=tty'
alias egrep='egrep --color=tty'

# Safety
alias cp='cp -i' # Prompt before overwriting

# Performance
alias make='make -j6' # Parallelize make with 6 cores.

# Editing
alias emacs-nox='emacs --no-window-system' # Functionally equivalent, and works on distros where emacs and emacs-nox packages conflict.
alias emac='emacs-nox' # Save a letter and skip the GUI when calling emacs from Bash.
alias nano='emacs-nox' # Do the right thing despite old muscle memory.
alias vi='echo "Just use emacs."'
alias vim='echo "Just use emacs."'
alias ed='echo "What is this? I don'\''t even."'

# Gitting
alias gca='git commit -a'
alias gpom='git push origin master'