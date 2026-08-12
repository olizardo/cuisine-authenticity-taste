#!/bin/bash
# Convenient wrapper to reliably start the master queue in the background
nohup ./run_master_queue_smart.sh < /dev/null > logs/run_master_queue_all.log 2>&1 &
echo "Master queue started in the background. Tail logs/run_master_queue_all.log to monitor."
