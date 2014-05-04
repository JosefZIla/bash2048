#!/usr/bin/env bash

header="2048 (https://github.com/rhoit/2048)"
source board.sh

#important variables
declare -i score=0

declare -i blocks    # number of blocks present on board
declare -i flag_skip # flag that prevents doing more than one operation on single field in one step
declare -i moves     # stores number of possible moves to determine if player lost the game
declare ESC=$'\e'    # escape byte

#default config
declare -i board_size=4
declare -i target=2048

exec 3>/dev/null     # no logging by default

trap "end_game 0; exit" INT #handle INT signalp

function generate_piece {
	while true; do
		let pos=RANDOM%N
		let board[$pos] || {
			let board[$pos]=RANDOM%10?2:4
			break;
		}
	done
	let blocks++

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
#         $1 - push position, for horizontal push this is row, for vertical column
#         $2 - recipient piece, this will hold result if moving or joining
#         $3 - originator piece, after moving or joining this will be left empty
#         $4 - direction of push, can be either "up", "down", "left" or "right"
#         $5 - if anything is passed, do not perform the push, only update number of valid moves
#         $board - original state of the game board
# outputs:
#         $change    - indicates if the board was changed this round
#         $flag_skip - indicates that recipient piece cannot be modified further
#         $board     - new state of the game board

function push_blocks { #  $1: push position
	case $4 in
		u) let first=$2*board_size+$1;
		   let second=($2+$3)*board_size+$1;;
		d) let first=(index_max-$2)*board_size+$1;
		   let second=(index_max-$2-$3)*board_size+$1;;
		l) let first=$1*board_size+$2;
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
				printf "move piece with value ${board[$first]} from [$second] to [$first]\n" >&3
			else
				let moves++
			fi
			return
		}
		return
	}

  let ${board[$second]} && let flag_skip=1
  let "${board[$first]}==${board[second]}" && {
    if test -z $5; then
      let board[$first]*=2
      let "board[$first]==$target" && end_game 1
      let board[$second]=0
      let blocks-=1
      let change=1
      let score+=${board[$first]}
      printf "joined piece from [$second] with [$first], new value=${board[$first]}\n" >&3
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
}

function apply_push_up {
	# TODO: win case
	for ((j=0; j < $board_size; j++)); do
		drag=0
		for ((i=0; i < $board_size; i++)); do
			let i1=i*board_size+j
			let ${board[i1]} || { let drag+=1; continue; }
			let total=board[i1]

			let i2=i1+board_size

			# max_row + 1 is blank, thats why string comparision
			if [[ "${board[i1]}" == "${board[i2]}" ]]; then
				let total*=2
				let board[i2]=0
				let blocks--
			elif (( drag == 0 )); then
				continue;
			fi

			if (( drag < i )); then
				let i4=i1-board_size*drag-board_size
				if [[ "${board[i1]}" == "${board[i4]}" ]]; then
					let board[i4]*=2
					let board[i1]=0
					let blocks--
					let change++
					continue
				fi
			fi

			let board[i1]=0
			let i3=i1-board_size*drag
			let board[i3]=total
			let change++
		done
	done
}

function apply_push_dn {
	let i_beg=board_size-1
    i_end=-1
	i_dif=-1
	for ((j=0; j < board_size; j++)); do
		drag=0
		for ((i=i_beg; i != i_end; i+=i_dif)); do
			let i1=i*board_size+j
			let ${board[i1]} || { let drag+=1; continue; }
			let total=board[i1]

			let i2=i1-board_size

			# max_row + 1 is blank, thats why string comparision
			if [[ "${board[i1]}" == "${board[i2]}" ]]; then
				let total*=2
				let board[i2]=0
				let blocks--
			elif (( drag == 0 )); then
				continue;
			fi

			if (( drag < i )); then
				let i4=i1+board_size*drag+board_size
				if [[ "$total" == "${board[i4]}" ]]; then
					let board[$i4]*=2
					let board[i1]=0
					let blocks--
					let change++
					continue
				fi
			fi

			let board[i1]=0
			let i3=i1+board_size*drag
			let board[i3]=total
			let change++
		done
	done
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
        A) apply_push_up u;;
        B) apply_push_dn d;;
        C) apply_push r;;
        D) apply_push l;;
      esac
    }
  }
}

function end_game {
  let $1 && {
    echo "Congratulations you have achieved $target"
    exit
  }
  box_board_terminate
  tput cup 9 0
  figlet -c -w $COLUMNS "GAME OVER"
  tput cup 22 80
  stty echo
  tput cnorm
}


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

# init board
function main {
	let N=board_size*board_size
	let index_max=board_size-1

	declare -ia board
	for ((i=N-1; i>= 0; i--)); do
		board[$i]=0
	done

	let blocks=0
	generate_piece
	generate_piece

	#board[0]=2
	#board[4]=2
	#board[8]=2
	#board[12]=2

	box_board_init $board_size
	clear
	box_board_print $index_max

	while true; do
		change=0
		box_board_update
		key_react

		let change && {
			generate_piece;
			sleep .01
		}
		let blocks==N && { # TODO: from apply push
			check_moves
			let moves==0 && end_game 0
		}
	done
}

main
