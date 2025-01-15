#!/bin/zsh

function usage() {
    echo "Usage: $0 [-h] [-l] [-1 | -0 | -c | -j] <instance>"
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

# Check for no arguments
if [[ $# -eq 0 ]]; then
    echo "Error: Please provide an argument" >&2
    usage
    exit 1
fi

# Handle single argument cases
if [[ $# -eq 1 ]]; then
    case $1 in
        "-h")
            usage
            exit 0
            ;;
        "-l")
            gcloud compute instances list
            exit 0
            ;;
        *)
            usage
            echo "ERROR: Please specify either -h for usage, -l to list all available instances, or include both an action and instance name" >&2
            exit 2
            ;;
    esac
fi

# Handle two argument cases
if [[ $# -eq 2 ]]; then
    # Validate argument order
    if [[ $2 =~ ^- ]]; then
        usage
        echo "ERROR: Instance name should be the second argument, not an option" >&2
        exit 2
    fi
    
    INSTANCE=$2
    ZONE="--zone=us-central1-a"
    
    case $1 in
        "-1")
            echo "Starting gcp instance: $INSTANCE"
            exec gcloud compute instances start "$INSTANCE" $ZONE
            ;;
        "-0")
            echo "Stopping gcp instance: $INSTANCE"
            exec gcloud compute instances stop "$INSTANCE" $ZONE
            ;;
        "-c")
            echo "Connecting to gcp instance: $INSTANCE"
            exec gcloud compute ssh "$INSTANCE" $ZONE --internal-ip
            ;;
        "-j")
            echo "Connecting to gcp instance: $INSTANCE with port forwarding!"
            echo "Initializing jupyer-lab server!"
            REMOTE_CMD='
              echo "Current PATH: $PATH"
              echo "Sourcing conda..."
              source ~/bin/miniconda3/etc/profile.d/conda.sh
              echo "Activating conda base..."
              conda activate base
              echo "Conda environment: $CONDA_PREFIX"
              echo "Which jupyter-lab: $(which jupyter-lab)"
              echo "Starting jupyter-lab..."
              jupyter-lab --no-browser
            '
            exec gcloud compute ssh "$INSTANCE" $ZONE --internal-ip -- -L 8888:localhost:8888 \
                "bash --login -c '$REMOTE_CMD'"
            ;;
        *)
            usage
            echo "ERROR: Invalid action specified. Please use -1, -0, -c, or -j" >&2
            exit 2
            ;;
    esac
fi

# If we get here, too many arguments were provided
usage
echo "ERROR: Too many arguments provided" >&2
exit 2
