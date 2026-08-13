#!/bin/bash
echo "Watcher started: Waiting for Model 5 to complete..."

# Loop until the success message appears in the log
while ! grep -q "Finished music Model 5_var_rs" logs/music_hier_5_var_rs.log; do
    sleep 10
done

echo "Model 5 finished! Transitioning queue to systemd..."

# Kill the master queue bash script gracefully
pkill -f "run_master_queue_smart.sh"

# In case Model 6 just started, kill its R script so systemd can restart it cleanly
pkill -f "music_hier_6_relaxed_rs.R"

# Give processes a moment to terminate
sleep 2

# Start the native systemd queue
systemctl --user start acat-queue

echo "Transition complete! The queue is now managed by systemd."
