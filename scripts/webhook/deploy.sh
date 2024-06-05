#!/bin/bash
set -e


# Log start time and arguments
echo "-------------------------------------------"  
echo "Deployment started at: $(date)"  
echo "Arguments: $@"  
echo "-------------------------------------------"  

# Check if the "service" argument is empty
if [ -z "$1" ]; then
    echo "Service argument is empty. Skipping deployment."  
else
    # Run deployment
    DISABLE_ANSI=1 ENABLE_FORCE_RECREATE=1 make deploy services="$1"  
fi


# Log end time
echo "-------------------------------------------"  
echo "Deployment finished at: $(date)"  
echo "-------------------------------------------"  