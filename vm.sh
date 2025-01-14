#!/bin/zsh

function usage() {
	echo "Usage: $0 [-h] [-1 | -0 | -l] <instance>"
	echo "This is a simple helper script to start and stop gcloud instances. "
	echo "Options: "
	echo "          -h                           Show this help message "
	echo "          -1                           Start instance"
	echo "          -0                           Stop instance"
    echo "          -l                           List instances"
	echo "  <instance>                           Name of Instance"
}

if [[ $# -eq 0 ]]; then
  echo "Error: Please provide an argument"
  usage
  exit 1

elif [[ $# -lt 2 && $1 != "-h" ]]; then
  usage
  echo "ERROR: Please specify either -h for usage or include both an action and instance name" >&2
  exit 2

elif [[ $1 == "-h" ]]; then
  usage
  exit 0

elif [[ $2 == "-1" || $2 == "-0"  || $2 == "-l" ]]; then
  usage
  echo "ERROR: Please only specify one action. Do not use any of: -1, -0, or -l  simultaneously." >&2
  exit 2

else
	if [[ $1 == "-1" ]]; then
		ACTION="start"
		INSTANCE=$2
	elif [[ $1 == "-0" ]]; then
		ACTION="stop"
		INSTANCE=$2
	elif [[ $1 == "-l" ]]; then
		ACTION="list"
		INSTANCE=''
	else
		usage
		echo "you provided an incorrect action. please try again" >&2
		exit 2
	fi
fi

# source .zshrc so we can use the gcloud suite
source ~/.zshrc

if [[ $ACTION == "stop" ]]; then
	echo "${ACTION}ping gcp instance: $INSTANCE"
else
	echo "${ACTION}ing gcp instance: $INSTANCE"
fi

gcloud compute instances $ACTION $INSTANCE

exit 0
