#!/bin/bash
set -e


# Log start time and arguments
echo "-------------------------------------------"  
echo "Deployment started at: $(date)"  
echo "Arguments: $@"  
echo "-------------------------------------------"  

#Retrive the arguments
SERVICES=$1
ENABLE_FORCE_RECREATE=$2
DISABLE_REMOVE_ORPHANS=$3
DISABLE_ANSI=$4
ENABLE_GIT_PULL=$5 


# Check if the "service" argument is empty
if [ -z "$1" ]; then
    echo "Service argument is empty. Skipping deployment."  
else
    # Run deployment
    DISABLE_ANSI=$DISABLE_ANSI ENABLE_GIT_PULL=$ENABLE_GIT_PULL ENABLE_FORCE_RECREATE=$ENABLE_FORCE_RECREATE DISABLE_REMOVE_ORPHANS=$DISABLE_REMOVE_ORPHANS  make deploy services="$SERVICES"  
fi


# Log end time
echo "-------------------------------------------"  
echo "Deployment finished at: $(date)"  
echo "-------------------------------------------"  