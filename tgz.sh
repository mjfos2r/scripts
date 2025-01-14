#!/bin/zsh
# Or /bin/bash if on server ;)
# Michael J. Foster
# github.com/mjfos2r/scripts/fs_utils/tgz.sh # maybe this?

function usage() {
    echo "Usage: $0 [-h] [-v | -d] -i <input> [-o <output>]"
    echo " "
    echo "This is a simple helper script to easily create tarballs and their checksum "
    echo " "
    echo "Options: "
    echo "          -h                       Print this help message and exit cleanly."
    echo "          -v                       Run tar with verbose output to STDOUT."
    echo "          -d                       Create dialog box to monitor progress."
    echo "          -i <input>               The directory or file to compress"
    echo "          -o <output>              Name of tarball (Optional: Defaults to input basename)"
    echo " "
}

function with_dialog() {
    local input=$1
    local output=$2
    #local size=$3

    if ! (tar -cf - "$input" 2>/dev/null \
        | pv -n \
        | pigz -6 -p $(nproc) > "$output") 2>&1 \
        | dialog --gauge 'Progress' 7 50; then
        echo "Error during compression" >&2
        rm -f "$output"  # Clean up partial file
        return 1
    fi
    return 0
}

function without_dialog() {
    local input=$1
    local output=$2
    local opts=$3

    echo "Compressing $input to $output"
    if ! tar "$opts" - "$input" | pigz -6 -p $(nproc) > "$output"; then
        echo "Error during compression" >&2
        rm -f "$output"  # Clean up partial file
        return 1
    fi
    return 0
}

# setup vars
INPUT_OBJ=""
TARBALL=""
SIZE=0
VERBOSE=false
DIALOG=false
OPTS="-cf"

# parse args
while getopts "hi:o:v:d" opt; do
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
        d)
            DIALOG=true
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

if $VERBOSE; then
    echo "Running Tar with full verbosity!"
    OPTS="-cvf"
fi

if $DIALOG; then
    OPTS="-cf"
    SIZE=$(du -sb $INPUT_OBJ | awk '{print $1}')
fi

if $DIALOG; then
    with_dialog "$INPUT_OBJ" "$TARBALL" "$SIZE"
else
    without_dialog "$INPUT_OBJ" "$TARBALL" "$OPTS"
fi

# Only create checksum if compression succeeded
if [ -f "$TARBALL" ]; then
    echo "Getting checksum!"
    md5sum "$TARBALL" > "${TARBALL}.md5"
    echo "Done!"
    exit 0
else
    echo "ERROR: Compression failed" >&2
    exit 1
fi