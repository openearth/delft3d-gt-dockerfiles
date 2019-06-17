#!/usr/bin/env bash

# by default we're not on amazon
# See, also for alternatives
# http://serverfault.com/questions/462903/how-to-know-if-a-machine-is-an-ec2-instance
EC2=1
if [ -f /sys/hypervisor/uuid ] && [ $(head -c 3 /sys/hypervisor/uuid) == "ec2" ]; then
    # introspect the machine
    EC2=1
fi

# Amazon specific code goes here
if [ "$EC2" == "1" ]
then


    # check in arguments what to do.
    # cleanup -> synchronize files to S3 bucket and remove files from EFS
    # rerun -> synchronize simulation files from S3 to EFS
    for argument in $@; do
        if [ "$argument" == "cleanup" ]
        then
            # synchronize directory with on s3 (make sure you provision aws command lines (pip install aws-cli))
            aws s3 sync /data/input/ "s3://$s3bucket/data/dynamic/$uuid" --exact-time

            # Capture sync status
            SYNC_STATUS=$?

            # caputer number of files in the EFS Simulation directory 
            I="$(find /data/input/simulation -type f | wc -l)"

            # write tree log of the EFS directory
            ls -lhR /data/input/ > /data/EFStree.log

            # write tree log of the S3 directory
            aws s3 ls  "s3://$s3bucket/data/dynamic/$uuid" --recursive --summarize > /data/S3tree.log

            # write temporary tree log of S3 simulation directory
            aws s3 ls  "s3://$s3bucket/data/dynamic/$uuid/simulation" --recursive --summarize > /tmp/S3Simulationtree.log

            # capture number of files in the S3 Simulation directory
            J="$(grep  "^Total Objects:" /tmp/S3Simulationtree.log | grep -Eo "[0-9]+")"

            if [ "$I" == "$J" ] && [ "$SYNC_STATUS" == "0" ];
            then
                echo "start cleanup" >> /data/sync_cleanup.log
                rm -rf /data/input/*
                echo "All directories are removed" >> /data/sync_cleanup.log
            else
                echo "Didn't clean EFS directories" >> /data/sync_cleanup.log
                echo "Number of files in EFS directory: $I" >> /data/sync_cleanup.log
                echo "Number of files in S3 directory: $J" >> /data/sync_cleanup.log
                echo "SYNC_STATUS: $SYNC_STATUS" >> /data/sync_cleanup.log
            fi

            # sync logfile
            aws s3 sync /data/ "s3://$s3bucket/data/dynamic/$uuid/log" --exact-time --exclude "*" --include "*.log"

            # remove logfile
            rm -rf /data/*.log

        elif [ "$argument" == "rerun" ]
        then
            # backup the old output except the simulation folder
            aws s3 cp "s3://$s3bucket/data/dynamic/$uuid/" "s3://$s3bucket/data/dynamic/$uuid/backup/$version/" --exclude "simulation/*" --exclude "backup/*" --recursive
            # synchronize simulation folder from s3 back to the Elastic File System. Exclude ini file, this file is generated in do_docker_create task.
            echo "sync S3 to EFS"
            aws s3 sync "s3://$s3bucket/data/dynamic/$uuid/simulation" /data/output/simulation --exclude "input.ini" --exact-time
        
        # synchronize in loop (use in argo sidecar)
        elif [ "$argument" == "sync" ]
            echo "sync processing images in a loop"
        then
            while true
            do
                echo 'aws s3 sync /data/input/ "s3://$s3bucket/data/dynamic/$uuid/process" --exact-time'
                sleep 10m
            done
        fi
    done
fi

