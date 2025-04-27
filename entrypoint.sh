#!/bin/bash

###############################################################################
# Jenkins EntryPoint Script
#
# Primary Purpose:
# This script is intended to run as the Docker container entrypoint for a Jenkins
# instance, ensuring Jenkins starts correctly, granting necessary permissions,
# and automatically reloading the Configuration-as-Code (JCasC) setup when pipeline
# definition files change.
#
# 1. Start Jenkins with Docker socket access and wait until it’s online.
# 2. Load and watch local JCasC pipeline definition files.
# 3. Auto-reload JCasC via Jenkins CLI on changes and keep the container alive.
#
# Usage: This script should be specified as the ENTRYPOINT in the Dockerfile for
#        the Jenkins container to enable live-reloading of its Configuration-as-Code.
###############################################################################

set -e

# Local Jenkins config file to read from local project
LOCAL_JENKINS_YAML="/tmp/local-jenkins.yaml"

# Grant the 'jenkins' user read and write access to the Docker socket for running Docker commands
sudo /usr/bin/setfacl -m u:jenkins:rw- /var/run/docker.sock

# Run Jenkins in the background
/usr/local/bin/jenkins.sh &

# Store the process ID (PID) of the last background command
jenkins_pid=$!

# Check if Jenkins is online by attempting to reach http://localhost:8080.
# It gives Jenkins a short time to start and then retries with a sleep  
# between each attempt. If Jenkins doesn't respond with a 200 OK in max
# attempts,  the script exits with an error message.
sleep 5
attempts=0
max_attempts=8
while ! curl -s --head http://localhost:8080/ | grep -q "HTTP/1.1 200 OK"; do
    attempts=$((attempts + 1))
    echo "[entrypoint] Jenkins is not online. Retrying $attempts/$max_attempts"
    if [ "$attempts" -ge "$max_attempts" ]; then
        echo "[entrypoint] ERROR: Jenkins is not online after $max_attempts attempts."
        exit 1
    fi
    sleep 3
done


# Extract the list of Jenkinsfiles from the Jenkins local YAML config
# Prepend the local project path to each file
# Assemble them into a single space-separated string for inotifywait
watch_list=$(yq -r '.jobs[].file' "$LOCAL_JENKINS_YAML" | sed 's|^|/mnt/local-project/|' | xargs)

# Print the list of files that will be watched
echo "[entrypoint] Watching files for changes: $watch_list"

# This downloads the Jenkins CLI tool and uses it to reload the Jenkins
# Configuration as Code (JCasC) settings. It monitors the watch list files
# for changes using inotifywait, and reloads the JCasC when a change is detected.

cd /tmp
curl -Os http://localhost:8080/jnlpJars/jenkins-cli.jar 

reload_jcasc() {
  java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin reload-jcasc-configuration
}

reload_jcasc

# Use inotifywait to monitor the Jenkinsfiles and reload the jcasc file on a change
while true; do
    changed_file=$(inotifywait -e modify --format '%w%f' $watch_list)
    echo "[entrypoint] $changed_file updated."
    reload_jcasc
done

# Wait for Jenkins to finish
wait $jenkins_pid
