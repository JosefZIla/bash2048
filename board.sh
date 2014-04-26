#!/bin/bash

lcorn=("╔" "╟" "╚" "║")
rcorn=("╗" "╢" "╝" "║")
cross=("╤" "┼" "╧" "│")
lines=("═" "─" "═" " ")


function get_color { # arg($1:color_code)
    if [ "$SGR" = "" ] ; then
		echo "\033[$1;$2m"
    fi
}

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
_colors[256]="\033[45;38m"		# bg:blue
_colors[512]="\033[45;38m"		# bg:cyan
_colors[1024]="\033[45;38m"		# bg:purple
_colors[2048]="\033[45;38m"		# bg:red

b_height=$(((24/4)-3))
b_width=$(((24*2/4)-1))

function print_x { # $1: char, $2:repeate
	for ((l=0; l<$2; l++)); do
		printf "$1";
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
		if (($i==1)); then
			printf "%6d" $val
			print_x " " 5
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
	for ((i=-1; i < $b_height; i++)); do
		printf "${lcorn[3]}";
		for ((j=0; j < $1; j++)); do
			print_value $3 $j $i
			printf "${cross[3]}"
		done
		print_value $3 $j $i
		echo "${rcorn[3]}"
	done
}

function box_board { # $1: size
	clear
	echo "$header"
	printf "pieces: %-9d" "$pieces"
	printf "target: %-9d" "$target"
	printf "score: %-9d" "$score"
	echo

	field=1
	line_printer $1 0
	for ((r=0; r <= $1; )); do
		block_printer $1 3 $r
		line_printer $1 $field

		r=$((r+1))
		if (($r == $1)); then
			field=2
		fi
	done
}

if [ `basename $0` == "board.sh" ]; then
	box_board 3
fi
