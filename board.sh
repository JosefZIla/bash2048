#!/bin/bash

lcorn=("╔" "╟" "╚" "║")
rcorn=("╗" "╢" "╝" "║")
cross=("╤" "┼" "╧" "│")
lines=("═" "─" "═" " ")

# for colorizing numbers
declare -a _colors
_colors[0]="\033[m"
_colors[2]="\033[1;38;5;8;48;5;255m"
_colors[4]="\033[1;38;245;12;48;5;12m"
_colors[8]="\033[1;31;48;5;214m"
_colors[16]="\033[1;39;48;5;202m"
_colors[32]="\033[1;39;48;5;9m"
_colors[64]="\033[1;39;48;5;1m"
_colors[128]="\033[1;30;48;5;11m"
_colors[256]="\033[1;30;48;5;10m"
_colors[512]="\033[46;39m"
_colors[1024]="\033[1;38;5;22;48;5;226m"
_colors[2048]="\033[1;38;5;244;48;5;228m"

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

function block_printer { # $1: total_columns
	for ((i=1; i <= $b_height; i++)); do
		line_printer $1 3
	done
}

function box_board_print { # $1: size
	echo "$header"
	status
	field=1
	#print_x "\n" $offset_y
	line_printer $1 0
	for ((r=0; r <= $1; r++ )); do
		if (($r == $1)); then
			field=2
		fi
		block_printer $1
		line_printer $1 $field
	done
}

function status {
	printf "pieces: %-9d" "$pieces"
	printf "target: %-9d" "$target"
	printf "score: %-9d" "$score"
	echo
}

function update_block { # $1: row, $2: column
	index=$(($1*${board_size}+$2))
	val=${board[$index]}

	if [[ $val == "" ]]; then # NOTE: only for test
		pow=$(($RANDOM%12))
		val=$(echo 2^$pow | bc)
	fi

	if [[ $val == 0 ]]; then
		val=" "
	fi

	for ((i=1; i <= $b_height; i++)); do
		# TODO: check difference while updating

		tput cup $((2+$1*b_height+i+$1)) $((1+offset_x+b_width*$2+$2))
		printf "${_colors[$val]}"
		if (($i==$mid_y)); then
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
			update_block $r $c
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
	b_width=$((b_height*2+3))
	mid_x=$((b_width/2+1))
	mid_y=$((b_height/2+1))
	mid_xr=$((b_width-mid_x))

	offset_x=$((COLUMNS/2-b_width*size/2-3))
	#offset_y=$((LINES/2-b_height*size/2))

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
	clear
	s=4

	if [[ $# -eq 1 ]] && (( "$1" > -1 )); then
		s=$1
	fi

	trap "box_board_terminate; exit" INT

	box_board_init $s

	echo -n block_size"(h,w)":$b_height","$b_width
	echo -n mid"(x,y)":$mid_x"x"$mid_y
	echo -n offset"(x,y)":$offset_x","$offset_y
	echo -n lines:$LINES column:$COLUMNS

	box_board_print $((size-1))
	while true; do
		read -sn 1 #-d "" -sn 1
		box_board_update
	done
fi
