#!/bin/bash

usage() { echo "Usage: $0 [-g] <SCHEDULER|>" 1>&2; exit 1; }
GPU=0
while getopts ":g" o; do
    case "${o}" in
        g)
            GPU=1 #${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

ROLE=$1
HOSTNAME=$HOSTNAME

#MAX_SYSTEM_MEMORY=$(free -m | awk '/^Mem:/{print $2}')M
#DEVICE_MEMORY_LIMIT="29GB"
#POOL_SIZE="31GB"
## A100 big mem
## DEVICE_MEMORY_LIMIT="70GB"
## POOL_SIZE="78GB"

# Used for writing scheduler file to shared storage
LOCAL_DIRECTORY=~/dask-local-directory
SCHEDULER_FILE=$LOCAL_DIRECTORY/scheduler.json
LOGDIR="$LOCAL_DIRECTORY/logs"
WORKER_DIR="/tmp/dask-workers/"
DASHBOARD_PORT=8787

# Purge Dask worker and log directories
if [ "$ROLE" = "SCHEDULER" ]; then
    rm -rf $LOCAL_DIRECTORY/*
    mkdir -p $LOGDIR
    rm -rf $WORKER_DIR/*
    mkdir -p $WORKER_DIR
fi

# Purge Dask config directories
rm -rf ~/.config/dask

# Dask/distributed configuration
export DASK_DISTRIBUTED__COMM__TIMEOUTS__CONNECT="100s"
export DASK_DISTRIBUTED__COMM__TIMEOUTS__TCP="600s"
export DASK_DISTRIBUTED__COMM__RETRY__DELAY__MIN="1s"
export DASK_DISTRIBUTED__COMM__RETRY__DELAY__MAX="60s"
export DASK_DISTRIBUTED__WORKER__MEMORY__Terminate="False"

sleep 2

if [ "$ROLE" = "SCHEDULER" ]
then
    # Setup scheduler
    if (($GPU == 1)); then
        ZE_AFFINITY_MASK=$PALS_LOCAL_RANKID DASK_DISTRIBUTED__WORKER__RESOURCES__GPU=1 nohup dask scheduler --dashboard-address $DASHBOARD_PORT --scheduler-file $SCHEDULER_FILE > $LOGDIR/$HOSTNAME-scheduler.log 2>&1 &
    else
        nohup dask scheduler --dashboard-address $DASHBOARD_PORT --scheduler-file $SCHEDULER_FILE > $LOGDIR/$HOSTNAME-scheduler.log 2>&1 &
    fi
fi

sleep 5
 
#if [ "$ROLE" != "SCHEDULER" ]
#then
# Setup workers   #  --no-nanny
if (($GPU == 1)); then
    ZE_AFFINITY_MASK=$PALS_LOCAL_RANKID DASK_DISTRIBUTED__WORKER__RESOURCES__GPU=1 dask worker --local-directory ${WORKER_DIR} --scheduler-file $SCHEDULER_FILE >> $LOGDIR/$HOSTNAME-worker.log 2>&1
else
    dask worker --local-directory ${WORKER_DIR} --scheduler-file $SCHEDULER_FILE >> $LOGDIR/$HOSTNAME-worker.log 2>&1
fi
#fi
