#!/bin/bash
# Michael J. Foster
# github.com/mjfos2r

# Script name
SCRIPT_NAME=$(basename "$0")

# Default values
verbose=false
input_file=""
output_dir="."

# Function to display usage
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [-h] [-v] [-i INPUT_FILE] [-o OUTPUT_DIR] 

A template script showing argument parsing and usage.

Options:
    -h          Display this help message
    -v          Enable verbose output
    -i FILE     Input file to process
    -o DIR      Output directory (default: current directory)

Examples:
    ${SCRIPT_NAME} -i input.txt -o /path/to/output -c 5
    ${SCRIPT_NAME} -v -i input.txt

EOF
    exit 1
}

# Logging function for verbose output. 
log() {
    if [ "$verbose" = true ]; then
        echo "[INFO] $1"
    fi
}

# Parse args 
while getopts "hvi:o:" opt; do
    case ${opt} in
        h)
            usage
            ;;
        v)
            verbose=true
            ;;
        i)
            input_file=$OPTARG
            ;;
        o)
            output_dir=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" 1>&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." 1>&2
            usage
            ;;
    esac
done

# Shift args 
shift $((OPTIND -1))

# Check required arguments
if [ -z "$input_file" ]; then
    echo "Error: Input file is required" 1>&2
    usage
fi

# Validate input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' does not exist" 1>&2
    exit 1
fi

# Validate output directory
if [ ! -d "$output_dir" ]; then
    echo "Error: Output directory '$output_dir' does not exist" 1>&2
    exit 1
fi

######################################################################   
#                                                                    #
#                                                                    #
#                  */ SCRIPT LOGIC BEGINS HERE */                    #
#                                                                    #
#                                                                    #
######################################################################   



# BD
exit 0
