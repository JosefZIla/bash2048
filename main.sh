#!/usr/bin/env bash

# variables
declare -i board_size=4
declare -i target=2048

function Usage {
    echo -e "Usage:  2048 [OPTIONS]";
    echo -e "\t-b | --board\tboard size"
    echo -e "\t-l | --level\tlevel 3-9"
    echo -e "\t-d | --debug\tdebug info"
    echo -e "\t-h | --help\tDisplay this message"
}

TEMP=$(getopt -o b:l:d:h\
              -l board:,level,debug,help\
              -n "2048"\
              -- "$@")

if [ $? != "0" ]; then exit 1; fi

eval set -- "$TEMP"

while true; do
	case $1 in
		-b|--board) board_size=$2; shift 2;;
		-l|--level) level=$2; shift 2;;
		-d|--debug) exec 3>$2; shift 2;;
		-h|--help)  Usage; exit;;
		--)         shift; break
	esac
done

# extra argument
for arg do
    level=$arg
    break
done

#----------------------------------------------------------------------
# late loading

WD="$(dirname $0)"
PRG="$(basename $0)"

header="2048 (https://github.com/rhoit/2048)"
export WD
source $WD/board.sh

declare -i score=0
declare ESC=$'\e' # escape byte

#exec 3>/dev/null # no logging by default
#printf "debug mode on" >&3

won_flag=0
trap "end_game 0; exit" INT #handle INT signal

function generate_piece {
	while (( blocks < N )); do
		let pos=RANDOM%N
		let board[$pos] || {
			let board[$pos]=RANDOM%10?2:4
			let blocks++
			break;
		}
	done
	change=1

	# just for some delay effects
	local r=$((pos/4))
	local c=$((pos-r*4))
	local val=${board[pos]}
	local c_temp=${_colors[val]}
	_colors[$val]="\033[48;5;15m"
	box_board_block_update $r $c
	_colors[$val]=$c_temp

}

# perform push operation between two blocks
# inputs:
#   $1 - push position, for horizontal push this is row, for vertical column
#   $2 - recipient piece, this will hold result if moving or joining
#   $3 - originator piece, after moving or joining this will be left empty
#   $4 - direction of push, can be either "up", "down", "left" or "right"
#   $5 - if anything is passed, do not perform the push, only update number of valid moves

function push_blocks {
	case $4 in
		u) let "first=$2*board_size+$1";
		   let "second=($2+$3)*board_size+$1";;
		d) let "first=(index_max-$2)*board_size+$1";
		   let "second=(index_max-$2-$3)*board_size+$1";;
		l) let "first=$1*board_size+$2";
		   let "second=$1*$board_size+($2+$3)";;
		r) let "first=$1*$board_size+(index_max-$2)";
		   let "second=$1*$board_size+(index_max-$2-$3)";;
	esac

	let ${board[$first]} || {
		let ${board[$second]} && {
			if test -z $5; then
				board[$first]=${board[$second]}
				let board[$second]=0
				let change=1
			else
				let moves++
			fi
		}
		return
	}

	let ${board[$second]} && let flag_skip=1
	let "${board[$first]}==${board[second]}" && {
		if test -z $5; then
			let board[$first]*=2
			let "board[$first]==$target" && won_flag=1
			let board[$second]=0
			let blocks-=1
			let change=1
			let score+=${board[$first]}
		else
			let moves++
		fi
	}
}

function apply_push { # $1: direction; $2: mode
	for ((i=0; i <= $index_max; i++)); do
		for ((j=0; j <= $index_max; j++)); do
			flag_skip=0
			let increment_max=index_max-j
			for ((k=1; k <= $increment_max; k++)); do
				let flag_skip && break
				push_blocks $i $j $k $1 $2
			done
		done
	done
	let won_flag && end_game 1
}

function check_moves {
	let moves=0
	apply_push u fake
	apply_push d fake
	apply_push l fake
	apply_push r fake
}

function key_react {
	read -d '' -sn 1
	test "$REPLY" = "$ESC" && {
		read -d '' -sn 1 -t1
		test "$REPLY" = "[" && {
			read -d '' -sn 1 -t1
			case $REPLY in
				A) apply_push u;;
				B) apply_push d;;
				C) apply_push r;;
				D) apply_push l;;
			esac
		}
	}
}

function end_game {
	if (( $1 == 1 )); then
		# TODO: get stty and dump for blink
		box_board_update
		status="YOU WIN"
	else
		status="GAME OVER"
	fi

	# TODO: remove figlet dependencies
	tput cup $offset_figlet_y 0; figlet -c -w $COLUMNS $status
	box_board_terminate
	exit
}

function main {
	let N=board_size*board_size
	let index_max=board_size-1

	let blocks=0
	declare -ia board
	for ((i=0; i < N; i++)); do
		board[$i]=0 #2048
		#let blocks++
	done

	# board[0]=0
	# board[4]=0
	# board[12]=2

	box_board_init $board_size
	clear
	box_board_print $index_max

	generate_piece
	while true; do
		let change && {
			generate_piece
			box_board_update
			change=0
			#sleep .01 &
		} #<&-

		key_react # before end game check, so player can see last board state

		let blocks==N && {
			check_moves
			let moves==0 && end_game 0
		}
	done
}

main
