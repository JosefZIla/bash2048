#!/bin/bash

declare -ia board
declare -ia joins
declare -i pieces=0
declare -i board_size=4
declare -i target=2048

header="Bash 2048 v0.3 by Josef Zila (josefzila@gmail.com)"
ESC=$'\e'

function print_header {
  echo $header pieces=$pieces
  echo
}

function print_board {
  clear
  print_header
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

function generate_token {
  let pieces==fields_total && end_game 0
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

function push_fields {
  case $3 in
    "up")
      let "first=$2*$board_size+$1"
      let "second=($2+1)*$board_size+$1"
      ;;
    "down")
      let "first=($2+1)*$board_size+$1"
      let "second=$2*$board_size+$1"
      ;;
    "left")
      let "first=$1*$board_size+$2"
      let "second=$1*$board_size+($2+1)"
      ;;
    "right")
      let "first=$1*$board_size+($2+1)"
      let "second=$1*$board_size+$2"
      ;;
  esac
  let "can_join=(!joins[$2])&(!joins[$2+1])"
  let ${board[$first]} || { 
    let ${board[$second]} && {
      board[$first]=${board[$second]}
      joins[$first]=${joins[$second]}
      let board[$second]=0
      let change=1
      return
    }
    return
  }
  let "(${board[$first]}==${board[second]})&(can_join)" && { 
    let board[$first]*=2
    let "board[$first]==$target" && end_game 1
    let board[$second]=0
    let joins[$2]=1
    let pieces-=1
    let change=1
  }
}

function make_push_rec {
  local n
  let "n=$2+1"
  push_fields $1 $2 $4
  let "n!=$3" && {
    make_push_rec $1 $n $3 $4
  }  
}

function push_tokens {
  for i in $(seq 0 $index_max); do
    for j in $(seq 0 $index_max); do joins[$j]="0"; done
    for pass in $(seq $index_max -1 1); do
      make_push_rec $i 0 $pass $1 
    done
  done
}

function key_react {
  let change=0
  read -d '' -sn 1
  test "$REPLY" = "$ESC" && {
    read -d '' -sn 1 -t1
    test "$REPLY" = "[" && {
      read -d '' -sn 1 -t1
      case $REPLY in
        A) push_tokens up;;
        B) push_tokens down;;
        C) push_tokens right;;
        D) push_tokens left;;
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
while getopts ":b:th" opt; do
  case $opt in
    b ) board_size="$OPTARG";;
    t ) target="$OPTARG";;
    h ) help $0
        exit 0;;
    \?) echo "Invalid option: -"$OPTARG", try $0 -h" >&2
            exit 1;;
    : ) echo "Option -"$OPTARG" requires an argument, try $0 -h" >&2
            exit 1;;
  esac
done

# check board size input
let '(board_size>=3)&(board_size<=9)' || {
  echo "Invalid board size, please choose size between 3 and 9"
  exit -1 
}

# check target input
echo "obase=2;$target" | bc | grep -e '^1[^1]*$'
let $? && {
  echo "Invalid target, has to be power of two"
  exit -1 
}

#init board
let fields_total=board_size*board_size
let index_max=board_size-1
for i in $(seq 0 $fields_total); do board[$i]="0"; done
for i in $(seq 0 $index_max); do joins[$i]="0"; done
generate_token
first_round=$last_added
generate_token
while true; do
  print_board
  key_react
  let change && generate_token
  first_round=-1
done 
