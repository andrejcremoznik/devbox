[[ $- != *i* ]] && return

# Save history
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoreboth,ignoredups
shopt -s histappend
export PROMPT_COMMAND='history -a'

# Aliases
alias ls='ls --group-directories-first --time-style=+"%d.%m.%Y %H:%M" --color=auto -F'
alias ll='ls -l --group-directories-first --time-style=+"%d.%m.%Y %H:%M" --color=auto -F'
alias la='ls -la --group-directories-first --time-style=+"%d.%m.%Y %H:%M" --color=auto -F'
alias grep='grep --color=tty -d skip'
alias cp='cp -i'
alias df='df -h'
alias free='free -m'

alias rfchmod='find . -type f -print0 | xargs -0 chmod 644'
alias rdchmod='find . -type d -print0 | xargs -0 chmod 755'

# Editor
export EDITOR=nano
export VISUAL=nano

# Prompt
PS1='[\u@\h \W]\$ '

# $PATH
PATH=$HOME/.bin:$HOME/.npm_global/bin:$PATH
