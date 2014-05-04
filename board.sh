#!/bin/bash

lcorn=("╔" "╟" "╚" "║")
rcorn=("╗" "╢" "╝" "║")
cross=("╤" "┼" "╧" "│")
lines=("═" "─" "═" " ")

_colors[0]="\033[m"
_colors[2]="\033[1;33;48;5;24m"
_colors[4]="\033[1;39;48;5;12m"
_colors[8]="\033[1;38;5;227;48;5;202m"
_colors[16]="\033[1;39;48;5;208m"
_colors[32]="\033[1;39;48;5;9m"
_colors[64]="\033[1;39;48;5;1m"
_colors[128]="\033[46;39m"
_colors[256]="\033[48;5;27;39m"
_colors[512]="\033[1;38;5;9;48;5;11m"
_colors[1024]="\033[1;38;5;22;48;5;226m"
_colors[2048]="\033[1;38;5;8;48;5;237m"

function print_x { # $1: char, $2:repeate
	for ((l=0; l<$2; l++)); do
		echo -en "$1";
	done
}

function line_printer { # $1: total_columns, $2: field
	printf "%${offset_x}s" " "
	printf "${lcorn[$2]}";
	for ((j=0; j < $1; j++)); do
		print_x "${lines[$2]}" $b_width
		printf "${cross[$2]}";
	done
	print_x "${lines[$2]}" $b_width
	echo "${rcorn[$2]}"
}

function box_board_print { # $1: size
	echo -e "$header"
	status
	#print_x "\n" $offset_y
	line_printer $1 0
	for ((r=0; r <= $1; r++ )); do
		let field=($r == $1)?2:1
		for ((i=1; i <= $b_height; i++)); do
			line_printer $1 3
		done
		line_printer $1 $field
	done
}

function status {
	printf "target: %-9d" "$target"
	printf "blocks: %-9d" "$blocks"
	printf "score: %-9d" "$score"
	printf "moves: %-9d" "$moves"
	echo
}

source font.sh
function block_update { # $1: x_position, $2: y_position, $3: val
	case $3 in
		2) two ;;
		4) four ;;
		8) eight;;
		16) sixteen;;
		32) thirtytwo;;
		64) sixtyfour;;
		128) onetwoeight;;
		256) twofivesix;;
		512) fiveonetwo;;
		1024) onezerotwofour;;
		2048) twozerofoureight;;
		*) block_update2 $1 $2 $3; return;;
	esac

	printf "${_colors[$3]}"
	for ((i=0; i < $b_height; i++)); do
		tput cup $(($1+i+1)) $2
		printf "${word[i]}"
	done
	printf "${_colors[0]}"
}

function box_board_block_update { # $1: row, $2: column
	local r=$1
	local c=$2
	local x=$((2+r*b_height+$r))
	local y=$((1+offset_x+b_width*c+c))

	local index=$(($r*$size+$c))
	local val=${board[index]}

	block_update $x $y $val
}

function block_update2 { # $1: x_position, $2: y_position, $3: val
	val=$3
	if [[ "$val" == 0 ]]; then
		val=" "
	fi

	for ((i=1; i <= $b_height; i++)); do
		tput cup $(($1+i)) $2
		printf "${_colors[$val]}"
		if (( i == mid_y )); then
			printf "%${mid_x}s" $val
			print_x " " $mid_xr
		else
			print_x "${lines[3]}" b_width
		fi
		printf "${_colors[0]}"
	done
}

function box_board_update {
	tput cup 1 0
	status
	for ((r=0; r < $size; r++)); do
		for ((c=0; c < $size; c++)); do
			box_board_block_update $r $c
		done
	done
}

function box_board_init { # $1: size
	size=$1
	LINES=$(tput lines)
	COLUMNS=$(tput cols)
	b_height=$((LINES/size))

	if ((b_height*size > LINE-5)); then
		b_height=$(((LINES-4-size)/size))
	fi

	let b_width=b_height*2+3
	let mid_x=b_width/2+1
	let mid_y=b_height/2+1
	let mid_xr=b_width-mid_x

	let offset_x=COLUMNS/2-b_width*size/2-3
	let offset_y=LINES/2-b_height*size/2

	screen_x=$((2+(b_height+1)*size))

	tput civis # hide cursor
	stty -echo # disable output
}

function box_board_terminate {
	tput cnorm # show cursor
	stty echo # enable output
	tput cup $screen_x $COLUMNS
}

if [ `basename $0` == "board.sh" ]; then
	s=4

	if [[ $# -eq 1 ]] && (( "$1" > -1 )); then
		s=$1
	fi

	trap "box_board_terminate; exit" INT

	box_board_init $s
	clear
	echo -n "block_size(hxw):${b_height}x$b_width "
	echo -n "mid(x,y):($mid_x,$mid_y) "
	echo -n "offset(x,y):($offset_x,$offset_y) "
	echo -n "size:${COLUMNS}x$LINES"

	box_board_print $((s-1))
	let N=s*s-1

	declare -ia board
	while true; do
		for ((i=N; i>= 0; i--)); do
			let pow=RANDOM%12
			board[$i]=$(echo 2^$pow | bc)
		done
		box_board_update
		read -sn 1 #-d "" -sn 1
	done
fi
