#!/bin/bash

declare -ia board
declare -i pieces=0
declare header="Bash 2048 v0.1 by Josef Zila (josefzila@gmail.com)"
declare ESC=$'\e'
declare lastmatch
declare change

function print_header {
  echo $header pieces=$pieces
  echo
}

function print_board {
  clear
  print_header
  printf '/------|------|------|------\\\n'
  for l in $(seq 0 3); do
    printf '| %4d | %4d | %4d | %4d |\n' ${board[l*4]} ${board[l*4+1]} ${board[l*4+2]} ${board[l*4+3]}
    let l==3 || printf '|------|------|------|------|\n'
  done
  printf '\\------|------|------|------/\n'
}

function generate_token {
  let pieces==16 && end_game 0
  while true; do
    let pos=RANDOM%16
    let board[$pos] || {
      let value=RANDOM%10?2:4
      board[$pos]=$value
      break;
    }
  done
  let pieces++
}

function push_fields {
  case $3 in
    "up")
      let "first=$2*4+$1"
      let "second=($2+1)*4+$1"
      ;;
    "down")
      let "first=($2+1)*4+$1"
      let "second=$2*4+$1"
      ;;
    "left")
      let "first=$1*4+$2"
      let "second=$1*4+($2+1)"
      ;;
    "right")
      let "first=$1*4+($2+1)"
      let "second=$1*4+$2"
      ;;
  esac      
  let ${board[$first]} || { 
    let ${board[$second]} && {
      board[$first]=${board[$second]}
      let board[$second]=0
      let change=1
      return
    }
    return
  }
  let "(${board[$first]}==${board[second]})&(lastmatch<$2)" && { 
    let board[$first]*=2
    let "board[$first]==2048" && end_game 1
    let board[$second]=0
    let lastmatch=$2+1
    let pieces-=1
    let change=1
  }
}

function make_push_rec {
  local n
  let "$2==$3" && return 
  let "n=$2+1"
  push_fields $1 $2 $4
  let "n!=$3" && {
    make_push_rec $1 $n $3 $4
    push_fields $1 $2 $4
    push_fields $1 $n $4
  }  
}

function push_tokens {
  let change=0
  let lastmatch=-1
  read -d '' -sn 1
  test "$REPLY" = "$ESC" && {
    read -d '' -sn 1 -t1
    test "$REPLY" = "[" && {
      read -d '' -sn 1 -t1
      case $REPLY in
        A) for i in $(seq 0 3); do lastmatch=-1; make_push_rec $i 0 3 up; done;;
        B) for i in $(seq 0 3); do lastmatch=-1; make_push_rec $i 0 3 down; done;;
        C) for i in $(seq 0 3); do lastmatch=-1; make_push_rec $i 0 3 right; done;;
        D) for i in $(seq 0 3); do lastmatch=-1; make_push_rec $i 0 3 left; done;;
      esac
    }
  }
}

function end_game {
  print_board
  echo GAME OVER
  let $1 && {
    echo "Congratulations you have achieved 2048"
    exit 0
  }
  echo "You have lost, better luck next time."
  exit 0
}

#start game
echo "Welcome to bash implementation of 2048"

#init board
for i in $(seq 0 15); do board[$i]="0"; done
generate_token
generate_token
while true; do
  print_board
  push_tokens
  let change && generate_token
done 
