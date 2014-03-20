#!/bin/bash

#important variables
declare -ia board    # array that keeps track of game status
declare -i pieces    # number of pieces present on board
declare -i flag_skip # flag that prevents doing more than one operation on
                     # single field in one step
declare -i moves     # stores number of possible moves to determine if player lost 
                     # the game
declare ESC=$'\e'    # escape byte
declare header="Bash 2048 v1.0 RC1 (bugs: https://github.com/mydzor/bash2048/issues)"

#default config
declare -i board_size=4
declare -i target=2048

# print currect status of the game, last added pieces are marked red
function print_board {
  clear
  echo $header pieces=$pieces target=$target
  echo
  printf '/------'
  for l in $(seq 1 $index_max); do
    printf '|------'
  done
  printf '\\\n'
  for l in $(seq 0 $index_max); do
    printf '| '
    for m in $(seq 0 $index_max); do
      if let ${board[l*$board_size+m]}; then
        if let '(last_added==(l*board_size+m))|(first_round==(l*board_size+m))'; then
          printf '\033[1m\033[31m%4d \033[0m| ' ${board[l*$board_size+m]}
        else
          printf '%4d | ' ${board[l*$board_size+m]}
        fi
      else
        printf '     | '
      fi
    done
    let l==$index_max || {
      printf '\n|------'
      for l in $(seq 1 $index_max); do
        printf '|------'
      done
      printf '|\n'
    }
  done
  printf '\n\\------'
  for l in $(seq 1 $index_max); do
    printf '|------'
  done
  printf '/\n'
}

# Generate new piece on the board
# inputs:
#         $board  - original state of the game board
#         $pieces - original number of pieces
# outputs:
#         $board  - new state of the game board
#         $pieces - new number of pieces
function generate_piece {
  while true; do
    let pos=RANDOM%fields_total
    let board[$pos] || {
      let value=RANDOM%10?2:4
      board[$pos]=$value
      last_added=$pos
      break;
    }
  done
  let pieces++
}

# perform push operation between two pieces
# inputs:
#         $1 - push position, for horizontal push this is row, for vertical column
#         $2 - recipient piece, this will hold result if moving or joining
#         $3 - originator piece, after moving or joining this will be left empty
#         $4 - direction of push, can be either "up", "down", "left" or "right"
#         $5 - if anything is passed, do not perform the push, only update number 
#              of valid moves
#         $board - original state of the game board
# outputs:
#         $change    - indicates if the board was changed this round
#         $flag_skip - indicates that recipient piece cannot be modified further
#         $board     - new state of the game board
function push_pieces {
  case $4 in
    "up")
      let "first=$2*$board_size+$1"
      let "second=($2+$3)*$board_size+$1"
      ;;
    "down")
      let "first=(index_max-$2)*$board_size+$1"
      let "second=(index_max-$2-$3)*$board_size+$1"
      ;;
    "left")
      let "first=$1*$board_size+$2"
      let "second=$1*$board_size+($2+$3)"
      ;;
    "right")
      let "first=$1*$board_size+(index_max-$2)"
      let "second=$1*$board_size+(index_max-$2-$3)"
      ;;
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
      let pieces-=1
      let change=1
    else
      let moves++
    fi
  }
}

function apply_push {
  for i in $(seq 0 $index_max); do
    for j in $(seq 0 $index_max); do
      flag_skip=0
      let increment_max=index_max-j
      for k in $(seq 1 $increment_max); do
        let flag_skip && break
        push_pieces $i $j $k $1 $2
      done 
    done
  done
}

function check_moves {
  let moves=0
  apply_push up fake
  apply_push down fake
  apply_push left fake
  apply_push right fake
}

function key_react {
  let change=0
  read -d '' -sn 1
  test "$REPLY" = "$ESC" && {
    read -d '' -sn 1 -t1
    test "$REPLY" = "[" && {
      read -d '' -sn 1 -t1
      case $REPLY in
        A) apply_push up;;
        B) apply_push down;;
        C) apply_push right;;
        D) apply_push left;;
      esac
    }
  }
}

function end_game {
  print_board
  echo GAME OVER
  let $1 && {
    echo "Congratulations you have achieved $target"
    exit 0
  }
  echo "You have lost, better luck next time."
  exit 0
}

function help {
  cat <<END_HELP
Usage: $1 [-b INTEGER] [-t INTEGER] [-h]

  -b			specify game board size (sizes 3-9 allowed)
  -t			specify target score to win (needs to be power of 2)
  -h			this help

END_HELP
}


#parse commandline options
while getopts "b:t:h" opt; do
  case $opt in
    b ) board_size="$OPTARG"
      let '(board_size>=3)&(board_size<=9)' || {
        echo "Invalid board size, please choose size between 3 and 9"
        exit -1 
      };;
    t ) target="$OPTARG"
      echo "obase=2;$target" | bc | grep -e '^1[^1]*$'
      let $? && {
        echo "Invalid target, has to be power of two"
        exit -1 
      };;
    h ) help $0
        exit 0;;
    \?) echo "Invalid option: -"$OPTARG", try $0 -h" >&2
            exit 1;;
    : ) echo "Option -"$OPTARG" requires an argument, try $0 -h" >&2
            exit 1;;
  esac
done

#init board
let fields_total=board_size*board_size
let index_max=board_size-1
for i in $(seq 0 $fields_total); do board[$i]="0"; done
let pieces=0
generate_piece
first_round=$last_added
generate_piece
while true; do
  print_board
  key_react
  let change && generate_piece
  first_round=-1
  let pieces==fields_total && {
   check_moves
   let moves==0 && end_game 0 #lose the game
  }
done 
