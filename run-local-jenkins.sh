#!/bin/bash
set -e

script_name=$(basename "$0")

CONTAINER_NAME=local-jenkins

cleanup_and_exit() {
    echo -e "\nCleaning up and exiting please wait..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    docker rm $CONTAINER_NAME > /dev/null 2>&1
    exit 0
}

# Trap interrupt signal (Ctrl+C) and call cleanup_and_exit function
trap 'cleanup_and_exit' INT

: "${LOCAL_JENKINS_PORT:=8080}"

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ $LOCAL = $REMOTE ]; then
    echo "[$script_name] INFO: Local branch is up to date with the remote branch."
elif [ $LOCAL = $BASE ]; then
    echo "[$script_name] WARNING: Local branch is behind the remote branch. Need to pull."
elif [ $REMOTE = $BASE ]; then
    echo "[$script_name] WARNING: Local branch is ahead of the remote branch. Need to push."
else
    echo "[$script_name] WARNING: Local and remote branches have diverged. Need to merge."
fi

LOCAL_JENKINS_DOCKER_SOCKET=$(echo $DOCKER_HOST | sed 's|unix://||')
LOCAL_JENKINS_DOCKER_BIN=$(which docker)

echo -e "\n\n[$script_name] LOCAL_JENKINS_DOCKER_SOCKET=$LOCAL_JENKINS_DOCKER_SOCKET"
echo -e "[$script_name] LOCAL_JENKINS_DOCKER_BIN=$LOCAL_JENKINS_DOCKER_BIN\n\n"

docker build -t ${CONTAINER_NAME} .

parent_directory=$(basename "$(dirname "$(pwd)")")

docker run -d \
  --name ${CONTAINER_NAME} \
  -p "$LOCAL_JENKINS_PORT:8080" \
  -v $(pwd)/../.:/mnt/local-project:ro \
  -v ${LOCAL_JENKINS_DOCKER_SOCKET}:/var/run/docker.sock \
  -v ${LOCAL_JENKINS_DOCKER_BIN}:/usr/bin/docker \
  -e LOCAL_JENKINS_JOB_NAME=$parent_directory \
  -e LOCAL_JENKINS_PORT=$LOCAL_JENKINS_PORT \
  ${CONTAINER_NAME}

docker logs -f ${CONTAINER_NAME}


