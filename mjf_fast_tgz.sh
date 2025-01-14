#!/bin/bash
# Michael J. Foster
# https://github.com/mjfos2r
# 2025 January 3
set -o pipefail

function usage() {
    echo "Usage: $0 [-h] -i <input> [-o <output>]"
    echo " "
    echo "This is a simple helper script to easily create tarballs and their checksum "
    echo " "
    echo "Options: "
    echo "          -h                       Print this help message and exit cleanly."
    echo "          -i <input>               The directory or file to compress"
    echo "          -o <output>              Name of tarball (Optional: Defaults to input basename)"
    echo " "
}

function check_input() {
    local input=$1
    if [[ ! -f "$input" ]]; then
        echo "Error: Input file does not exist" >&2
        return false
    fi
    return true
}

function compress() {
    local input=$1
    local output=$2
    local size=$3

    (tar -cvf - "$input" 2>/tmp/tar.log \
    | pv -n -s $size \
    | pigz -p $(nproc) > "$output") 2>&1 >/tmp/tar.prog
}

function get_checksum() {
    local input="$1"
    local output="${input}.md5"

    if not $(check_input $input); then
        return 1
    fi

    # Get size once to ensure consistency
    local size=$(du -sb "$input" | awk '{print $1}')

    # Generate checksum while showing progress
    pv -n -s "$size" "$input" | \
    tee >(md5sum > "$output") >/tmp/md5sum.log || {
        echo "Error generating checksum" >&2
        rm -f "$output"
        return 1
    } 2>&1
    return 0
} 2>&1

function upload_to_bucket() {
    local input=$1
    local bucket=$2
    local checksum="${input}.md5"

    gsutil cp -m $input $bucket >/tmp/bucket_upload.log || {
    echo "ERROR UPLOADING TARBALL TO BUCKET!" >&2
    return 1
    } 2>&1
    return 0
} 2>&1

# setup vars
INPUT_OBJ=""
TARBALL=""
SIZE=0

function setup_dialog_layout() {
    clear
    dialog --create-rc ~/.dialogrc
    echo 'aspect = 0' >> ~/.dialogrc

    dialog --keep-window --begin 3 5 --title "Compression Progress" \
           --infobox "Waiting to start..." 3 70 ""

    dialog --keep-window --begin 8 5 --title "Checksum Progress" \
           --infobox "Waiting to start..." 3 70 ""

    dialog --keep-window --begin 13 5 --title "Upload Progress" \
           --infobox "Waiting to start..." 3 70 ""
}
# parse args
while getopts "hi:o" opt; do
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

# run compression on input
 AND combine with following code to create a progress bar for the compression function, the checksum function, and also the gsutil upload function.
        | dialog --keep-window --begin 18 55 --tailboxbg /tmp/tar.log 18 100 \
        --and-widget --keep-window --begin 10 70 --gauge 'Progress' 7 70; then
        dialog --begin 20 70 --infobox "ERROR: Unkown error during compression" 10 70
        rm -f "$output"  # Clean up partial file
        return 1
    fi
    return 0