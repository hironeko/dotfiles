#!/bin/bash

# use colors on terminal
tput=$(which tput)
if [ -n "$tput" ]; then
    ncolors=$($tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi

### functions
# info: output terminal green
info() {
    echo "${GREEN} info ${NORMAL} $1"
}

error() {
    printf "${RED}"
    echo -n "  error "
    printf "${NORMAL}"
    echo "$1"
}

# warn: output terminal yellow
warn() {
    printf "${YELLOW}"
    echo -n "  warn  "
    printf "${NORMAL}"
    echo "$1"
}

# log: out put termial normal
log() { 
    echo "  $1" 
}

