#!/bin/bash

lcorn=("╔" "╟" "╚" "║")
rcorn=("╗" "╢" "╝" "║")
cross=("╤" "┼" "╧" "│")
lines=("═" "─" "═" " ")

#for colorizing numbers
declare -a _colors
_colors[0]="\033[m"
_colors[2]="\033[33m"			# fg:yellow
_colors[4]="\033[32m"			# fg:green
_colors[8]="\033[34m"			# fg:blue
_colors[16]="\033[36m"			# fg:cyan
_colors[32]="\033[35m"			# fg:purple
_colors[64]="\033[43;38m"		# bg:yellow
_colors[128]="\033[42;38m"		# bg:green
_colors[256]="\033[43;38m"		# bg:blue
_colors[512]="\033[46;38m"		# bg:cyan
_colors[1024]="\033[45;38m"		# bg:purple
_colors[2048]="\033[41;38m"		# bg:red

function print_x { # $1: char, $2:repeate
	for ((l=0; l<$2; l++)); do
		echo -n "$1";
	done
}

function print_value { # $1: row, $2:column, $3:mid_block
	# TODO: auto center
	index=$(($1*${board_size}+$2))
	val=${board[$index]}
	if [[ "$val" == 0 ]]; then
		print_x "${lines[3]}" $b_width
	else
		printf "${_colors[$val]}"
		if (($i==$mid_y)); then
			printf "%${mid_x}d" $val
			print_x " " $mid_xr
		else
			print_x "${lines[3]}" b_width
		fi
		printf "${_colors[0]}"
	fi
}

function line_printer { # $1: total_columns, $2: field
	printf "${lcorn[$2]}";
	for ((j=0; j < $1; j++)); do
		print_x "${lines[$2]}" $b_width
		printf "${cross[$2]}";
	done
	print_x "${lines[$2]}" $b_width
	echo "${rcorn[$2]}"
}


function block_printer { # $1: total_columns, $2: field, $3: row
	for ((i=1; i <= $b_height; i++)); do
		printf "${lcorn[3]}";
		for ((j=0; j < $1; j++)); do
			print_value $3 $j $i
			printf "${cross[3]}"
		done
		print_value $3 $j $i
		echo "${rcorn[3]}"
	done
}

function status {
	printf "pieces: %-9d" "$pieces"
	printf "target: %-9d" "$target"
	printf "score: %-9d" "$score"
	echo
}

function box_board { # $1: size
	echo "$header"
	status
	field=1
	line_printer $1 0
	for ((r=0; r <= $1; r++ )); do
		if (($r == $1)); then
			field=2
		fi
		block_printer $1 3 $r
		line_printer $1 $field
	done
}

function update_block { # $1: row, $2: column
	#index=$(($1*${board_size}+$2))
	#val=${board[$index]}
	pow=$(($RANDOM%12))
	val=$(echo 2^$pow | bc)

	for ((i=1; i <= $b_height; i++)); do
		# TODO: check differenc while updating
		# if [[ "$val" == 0 ]]; then
		# 	print_x "${lines[3]}" $b_width
		# else
		tput cup $((2+$1*b_height+i+$1)) $((1+b_width*$2+$2))
		printf "${_colors[$val]}"
		if (($i==$mid_y)); then
			printf "%${mid_x}d" $val
			print_x " " $mid_xr
		else
			print_x "${lines[3]}" b_width
		fi
		printf "${_colors[0]}"
	done
}

function update_board {
	tput cup 1 0
	status
	for ((r=0; r < $size; r++)); do
		for ((c=0; c < $size; c++)); do
			update_block $r $c
		done
	done
	tput cup 23 0
}

function init {
	LINES=$(tput lines)
	b_height=$((LINES/size))
	if ((b_height*size > LINE-5)); then
		b_height=$(((LINES-4-size)/size))
	fi
	b_width=$((b_height*2+3))
	mid_x=$((b_width/2+1))
	mid_y=$((b_height/2+1))
	mid_xr=$((b_width-mid_x))
}

if [ `basename $0` == "board.sh" ]; then
	size=4

	if [[ $# -eq 1 ]] && (( "$1" > -1 )); then
		size=$1
	fi

	init
	clear
	echo -n block_size:$b_height"x"$b_width mid:$mid_x"x"$mid_y lines:$LINES
	box_board $((size-1))
	while true; do
		read -sn 1 #-d "" -sn 1
		update_board
	done
else
	size=board_size
	init
fi
