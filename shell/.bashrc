# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
alias vi=vim
alias ls='ls -G'
alias ll='ls -lF -G'
alias lrt='ls -lrt -G'
alias l='ls -lA -G'
alias cls="clear"
alias c=cd
alias d=cd
alias tailf="tail -f"
alias uuid=uuidgen

export PS1="\n[ \[\e[0;35m\]\u\[\e[0m\]@\[\e[0;31m\]\`hostname\`\[\e[0m\]:\[\e[0;33m\]\`pwd\`\[\e[0m\] \[\e[0;32m\]\`date '+%Y-%m-%d %H:%M:%S %a'\`\[\e[0m\] ]\n\\\$ "
