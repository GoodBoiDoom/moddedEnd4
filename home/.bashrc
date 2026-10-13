#
# ~/.bashrc
#
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
if not running interactively, don't do anything
[[ $- != *i* ]] && return
neofetch
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

