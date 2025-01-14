#!/bin/bash
# Michael J. Foster
# https://github.com/mjfos2r
# 2025 January 3
set -o pipefail

function usage() {
    echo "Usage: $0 [-h] -i <input> [-o <output>] [-b <bucket>]"
    echo " "
    echo "This is a simple helper script to easily create tarballs and their checksum "
    echo " "
    echo "Options: "
    echo "          -h                       Print this help message and exit cleanly."
    echo "          -i <input>               The directory or file to compress"
    echo "          -o <output>              Name of tarball (Optional: Defaults to input basename)"
    echo "          -b <bucket>              GCS bucket to upload to (Optional)"
    echo " "
}

function check_input() {
    local input=$1
    if [[ ! -f "$input" ]]; then
        echo "Error: Input file does not exist" >&2
        return 1
    fi
    return 0
}

function compress() {
    local input=$1
    local output=$2
    local size=$(du -sb "$input" | awk '{print $1}')
    local progress=0

    dialog --title "Compression" \
           --begin 3 5 \
           --gauge "Starting compression..." 7 70 0 &
    local gauge_pid=$!

    dialog --begin 18 5 \
           --tailboxbg /tmp/tar.log 8 70 &
    local tail_pid=$!

    (tar -cvf - "$input" 2>/tmp/tar.log | \
     pv -n -s "$size" 2>/tmp/tar.prog | \
     pigz -p $(nproc) > "$output") &
    local tar_pid=$!

    while [ -e /proc/$tar_pid ]; do
        if [ -f /tmp/tar.prog ]; then
            progress=$(cat /tmp/tar.prog)
            dialog --begin 3 5 \
                   --gauge "Compressing $input..." 7 70 $progress
        fi
        sleep 0.1
    done

    wait $tar_pid || {
        kill $gauge_pid $tail_pid
        rm -f "$output" /tmp/tar.prog /tmp/tar.log
        return 1
    }

    kill $gauge_pid $tail_pid
    rm -f /tmp/tar.prog /tmp/tar.log
    return 0
}

function get_checksum() {
    local input="$1"
    local output="${input}.md5"
    local size=$(du -sb "$input" | awk '{print $1}')
    local progress=0

    dialog --title "Checksum" \
           --begin 11 5 \
           --gauge "Starting checksum calculation..." 7 70 0 &
    local gauge_pid=$!

    (pv -n -s "$size" "$input" 2>/tmp/md5.prog | \
     tee >(md5sum > "$output") >/dev/null) &
    local md5_pid=$!

    while [ -e /proc/$md5_pid ]; do
        if [ -f /tmp/md5.prog ]; then
            progress=$(cat /tmp/md5.prog)
            dialog --begin 11 5 \
                   --gauge "Calculating checksum..." 7 70 $progress
        fi
        sleep 0.1
    done

    wait $md5_pid || {
        kill $gauge_pid
        rm -f "$output" /tmp/md5.prog
        return 1
    }

    # Display the checksum
    local checksum=$(cat "$output" | cut -d' ' -f1)
    dialog --begin 19 5 \
           --title "MD5 Checksum" \
           --infobox "MD5: $checksum" 3 70

    kill $gauge_pid
    rm -f /tmp/md5.prog
    return 0
}

function upload_to_bucket() {
    local input=$1
    local bucket=$2
    local size=$(du -sb "$input" | awk '{print $1}')
    local progress=0

    dialog --title "Upload" \
           --begin 23 5 \
           --gauge "Starting upload..." 7 70 0 &
    local gauge_pid=$!

    (pv -n -s "$size" "$input" 2>/tmp/upload.prog | \
     gsutil cp - "$bucket/$(basename $input)" >/dev/null 2>&1) &
    local upload_pid=$!

    while [ -e /proc/$upload_pid ]; do
        if [ -f /tmp/upload.prog ]; then
            progress=$(cat /tmp/upload.prog)
            dialog --begin 23 5 \
                   --gauge "Uploading to $bucket..." 7 70 $progress
        fi
        sleep 0.1
    done

    wait $upload_pid || {
        kill $gauge_pid
        rm -f /tmp/upload.prog
        return 1
    }

    kill $gauge_pid
    rm -f /tmp/upload.prog
    return 0
}

# Main script logic
INPUT_OBJ=""
TARBALL=""
BUCKET=""

# Parse args
while getopts "hi:o:b:" opt; do
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
        b)
            BUCKET="$OPTARG"
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

# Check args
if [[ -z $INPUT_OBJ ]]; then
    echo "ERROR: You must specify an input (-i). Check your command and try again." >&2
    exit 2
fi

# Input must exist
if [[ ! -f "$INPUT_OBJ" && ! -d "$INPUT_OBJ" ]]; then
    echo "ERROR: $INPUT_OBJ is neither a file nor directory" >&2
    exit 2
fi

# If no output_name, use basename
if [[ -z "$TARBALL" ]]; then
    TARBALL="$(basename "$INPUT_OBJ").tar.gz"
fi

# Clear screen and start processing
clear

# Run compression
compress "$INPUT_OBJ" "$TARBALL" || {
    dialog --msgbox "Error during compression" 5 40
    clear
    exit 1
}

# Calculate checksum
get_checksum "$TARBALL" || {
    dialog --msgbox "Error generating checksum" 5 40
    clear
    exit 1
}

# Upload if bucket specified
if [[ -n "$BUCKET" ]]; then
    upload_to_bucket "$TARBALL" "$BUCKET" || {
        dialog --msgbox "Error uploading to bucket" 5 40
        clear
        exit 1
    }
fi

sleep 2
clear
echo "All operations completed successfully!"
exit 0