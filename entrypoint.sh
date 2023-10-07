#!/bin/bash

set -e

sudo /usr/bin/setfacl -m u:jenkins:rw- /var/run/docker.sock

echo "[entrypoint.sh] docker info:"
docker info

security_options=$(docker info --format '{{.SecurityOptions}}')

if [[ $security_options != *"rootless"* ]]; then
    if [ "$LOCAL_JENKINS_ALLOW_ROOTLESS" = "true" ]; then
        echo
        echo "[entrypoint.sh] WARNING: Docker is NOT in rootless mode. Continuing"
        echo "                because LOCAL_JENKINS_ALLOW_ROOTLESS is true."
        echo "                See more https://docs.docker.com/engine/security/rootless/"
        echo
    else
        echo "[entrypoint.sh] ERROR: Docker Rootless mode is not enabled. It is"
        echo "                recommend to run docker in rootless mode."
        echo "                See more https://docs.docker.com/engine/security/rootless/" 
        echo "                To override set LOCAL_JENKINS_ALLOW_ROOTLESS=true"
        exit 1
    fi
else
    echo "[entrypoint.sh] INFO: docker rootless mode enabled."
fi

# Run Jenkins in the background
/usr/local/bin/jenkins.sh &

# Store the process ID (PID) of the last background command
jenkins_pid=$!

# Wait for Jenkins to be accessible at http://localhost:8080/
echo "[entrypoint.sh] Waiting for Jenkins to be accessible..."
while ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ | grep -q "200"; do
    sleep 1
done

cd /tmp
curl -Os http://localhost:8080/jnlpJars/jenkins-cli.jar 
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin reload-jcasc-configuration

echo "[entrypoint.sh] http://localhost:8080/"

# Use inotifywait to monitor the Jenkinsfile and reload the jcasc file on a change.
jenkinsfile=/mnt/local-project/Jenkinsfile
while true; do
    inotifywait -e modify "$jenkinsfile"
    echo "[entrypoint.sh] $jenkinsfile updated."
    java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin reload-jcasc-configuration
done

# Wait for Jenkins to finish
wait $jenkins_pid
