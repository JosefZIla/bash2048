#!/bin/bash

# for colorizing numbers

c0="\033[1;m"
c1="\033[1;31m"
c2="\033[1;38;5;22m"
c3="\033[1;32m"
c4="\033[1;38;5;226m"
c5="\033[1;34m"
c6="\033[1;35m"

header="${c1}2${c4}0${c5}4${c3}8${c0} (https://github.com/rhoit/2048)"

function printer { # $1: value
	for ((i=0; i<4; i++)); do
		echo "${word[$i]}"
	done
}

declare -a word

function two {
	word[0]="    ▃▄▄▃   "
	word[1]="   ▝▘  ▄▀  "
	word[2]="    ▄▀▀    "
	word[3]="   ▀▀▀▀▀▀  "
}

function four {
	word[0]="      ▄▆   "
	word[1]="    ▄▀ █   "
	word[2]="   ▀▀▀▀█▀  "
	word[3]="       ▀   "
}

function eight {
	word[0]="    ▄▄▄▄   "
	word[1]="   █ ▂▃▄▀  "
	word[2]="   ▄▀▔  █  "
	word[3]="    ▀▀▀▀   "
}

function sixteen {
	word[0]="  ▗▄ ▗▄▄▖  "
	word[1]="   █ █▄▄   "
	word[2]="   █ █  █  "
	word[3]="   ▀  ▀▀   "
}

function thirtytwo {
	word[0]=" ▗▄▄▄▖▂▄▄  "
	word[1]="   ▄▀ ▔ ▄█ "
	word[2]=" ▗▖ ▜▖▃█▀  "
	word[3]="  ▝▀▀ ▀▀▀▀ "
}

function sixtyfour {
	word[0]=" ▗▄▄▖   ▄▆ "
	word[1]=" █▄▄  ▄▀ █ "
	word[2]=" █  █▝▀▀▀█▘"
	word[3]="  ▀▀     ▀ "
}

function onetwoeight {
	word[0]="           "
	word[1]="▝▌▀▀▀▖▗▀▀▀▖"
	word[2]=" ▌▄▀▀ ▗▀▀▀▖"
	word[3]=" ▘▀▀▀▘▝▀▀▀ "
}

function twofivesix {
	word[0]="           "
	word[1]=" ▀▀▖▐▀▀▗▀▀ "
	word[2]=" ▄▀  ▀▚▐▀▀▖"
	word[3]=" ▀▀▘▝▀▘ ▀▀ "
}

function fiveonetwo {
	word[0]="           "
	word[1]="▐▀▀▀▝█ ▀▀▀▖"
	word[2]=" ▀▀▄ █ ▄▀▀ "
	word[3]="▝▀▀  ▀ ▀▀▀▘"
}

function onezerotwofour {
	word[0]="           "
	word[1]="${c2}▝▌${c1}▛▜${c5}▝▀▚${c6} ▞▌ "
	word[2]="${c2} ▌${c1}▙▟${c5}▗▟▙${c6}▝▀▛ "
	word[3]="           "
}

function twozerofoureight {
	word[0]="        ${c3}▁▁ "
	word[1]="${c1}▝▀▚${c4}▛▜${c5} ▞▌${c3}▙▟ "
	word[2]="${c1}▗▟▙${c4}▙▟${c5}▝▀▛${c3}▙▟ "
	word[3]="           "
}

if [ `basename $0` == "font.sh" ]; then
	two; printer
	#four; printer
	eight; printer
	#sixteen; printer
	thirtytwo; printer
	sixtyfour; printer
	onetwoeight; printer
	twofivesix; printer
	fiveonetwo; printer
	twozerofoureight; printer
fi

# glyph_printer 2

	# tput cup $((2+0*b_height+1+0)) #$((1+offset_x+b_width*0+0))
	# #echo a
	# figlet -f small 2 -w $((1+offset_x+b_width*0+0+b_width)) -r
