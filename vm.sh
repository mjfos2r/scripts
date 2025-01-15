#!/bin/zsh

function usage() {
	echo "Usage: $0 [-h] [-l | -1 | -0 | -c | -j] <instance>"
	echo "This is a simple helper script to start and stop gcloud instances. "
	echo "Options: "
	echo "          -h                           Show this help message "
  echo "          -l                           List instances"
	echo "          -1                           Start instance"
	echo "          -0                           Stop instance"
	echo "          -c                           Connect to instance"
	echo "          -j                           Connect to instance with port forwarding (jupyter server)"
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

elif [[ $2 == "-l" || $2 == "-1"  || $2 == "-0" || $2 == "-c" || $2 == "-j" ]]; then
  usage
  echo "ERROR: Please only specify one action. Do not use any of: -1, -0, or -l  simultaneously." >&2
  exit 2

else
	if [[ $1 == "-1" ]]; then
		MODE="instances"
		ACTION="start"
		INSTANCE=$2
		OPTIONS=""
	elif [[ $1 == "-0" ]]; then
		MODE="instances"
		ACTION="stop"
		INSTANCE=$2
		OPTIONS=""
	elif [[ $1 == "-l" ]]; then
		MODE="instances"
		ACTION="list"
		INSTANCE=''
		OPTIONS=""
	elif [[ $1 == "-c" ]]; then
		MODE="ssh"
		ACTION="connect"
		INSTANCE=$2
		OPTIONS="--internal-ip --zone=us-central1-a"
	elif [[ $1 == "-j" ]]; then
		MODE="ssh"
		ACTION="jupyter"
		INSTANCE=$2
		OPTIONS="--internal-ip --zone=us-central1-a -- -L 8888:localhost:8888"
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

if [[ $ACTION == "connect" ]]; then
	echo "${ACTION}ing to  gcp instance: $INSTANCE"
elif [[ $ACTION == "jupyter" ]]; then 
	echo "${ACTION}ing to gcp instance: $INSTANCE with port forwarding!"
fi

exec gcloud compute $MODE $ACTION $INSTANCE $OPTIONS

exit 0
