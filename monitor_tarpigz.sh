#!/bin/bash

function usage() {
    echo "Usage: $0 [-h] [-v] -i <input> [-o <output>]"
    echo " "
    echo "This is a simple helper script to monitor a large `tar | pigz > out.tar.gz` compression job "
    echo " "
    echo "Options: "
    echo "          -h                       Print this help message and exit cleanly."
    echo "          -v                       Run with dialog box."
    echo "          -i <input>               The directory or file to compress"
    echo "          -o <output>              Name of tarball (Optional: Defaults to input basename)"
    echo " "
}

# setup vars
INPUT_OBJ=""
TARBALL=""
VERBOSE=false
OPTS="-cf"

# parse args
while getopts "hi:o:v" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        i)
            INPUT_OBJ="$OPTARG"
            ;;
        o)
            TARBALL="${OPTARG}.tar.gz"
            ;;
        v)
            VERBOSE=true
            ;;
        \?)
            echo "ERROR: Invalid option -$OPTARG" >&2
            exit 2
            ;;
        :)
            echo "ERROR: Option -$OPTARG requires an argument" >&2
            exit 2
            ;;
    esac
done

# check args
if [[ -z $INPUT_OBJ ]]; then
    echo "ERROR: You must specify an input (-i). check your command and try again." >&2
    exit 2
fi

# input's gotta exist
if [[ ! -f "$INPUT_OBJ" && ! -d "$INPUT_OBJ" ]]; then
    echo "ERROR: $INPUT_OBJ is neither a file nor directory" >&2
    exit 2
fi

# If no output_name, use basename.
if [[ -z "$TARBALL" ]]; then
    TARBALL="$(basename "$INPUT_OBJ").tar.gz"
fi

