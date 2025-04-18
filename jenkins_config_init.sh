#!/bin/bash

set -ex

yaml_file="/tmp/local-jenkins.yaml"

# PLUGINS

yq -r '.plugins[]' $yaml_file > /tmp/plugins.txt

plugin_file="/tmp/plugins.txt"

readarray -t required_plugins < require_plugins.txt

# Loop through each line in the array
for plugin in "${required_plugins[@]}"; do

  # Extract the part before the colon (e.g., 'configuration-as-code') for matching
  plugin_name="${plugin%%:*}"

  # Check if any line in the file starts with the prefix
  if grep -q "^$plugin_name" "$plugin_file"; then
    echo "WARNING: $plugin_name set in $yaml_file. This bypasses default plugin management of a required plugin. Use at your own risk."
  else
    echo "Adding local-jenkins required plugin '$plugin' to plugin install list."
    echo "$plugin" >> "$plugin_file"
  fi
done



# JOBS



add_jenkins_job() {
  local YAML_FILE="/var/lib/jenkins/jenkins.yaml"
  local JOB_NAME="$1"
  local JENKINSFILE_PATH="$2"

  # Append a new job to the jobs array using yq
  yq -y -i "
    .jobs += [{
      script: \"pipelineJob('$JOB_NAME') {
        theScript = new File('$JENKINSFILE_PATH').getText('UTF-8')
        definition {
          cps {
            script(theScript)
            sandbox()
          }
        }
      }\"
    }]
  " "$YAML_FILE"
}





# Assuming your YAML file is called jobs.yaml
yq -r '.jobs[] | "\(.name) \(.file)"' $yaml_file |
while read -r name file; do
  add_jenkins_job $name /mnt/local-project/$file
done
