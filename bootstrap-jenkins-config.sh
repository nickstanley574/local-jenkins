#!/bin/bash

###############################################################################
# Jenkins Setup Script
#
# Primary Purpose:
# This script is intended to be used during the Docker build process via the
# Dockerfile to set up a local Jenkins Docker image and container.
#
# 1. Validates required dependencies and necessary configuration files.
# 2. Merges required plugins into the local Jenkins plugin list to install.
# 3. Adds pipeline jobs to the JCasC YAML defined in the local Jenkins config.
#
# Usage: Called in the Dockerfile during image build.
###############################################################################

set -e

###############################################################################
# CONSTANTS
###############################################################################

# Path to the local project directory used for loading pipeline scripts
LOCAL_PROJECT_DIR="/mnt/local-project"

# Local Jenkins config file to read from local project
LOCAL_JENKINS_YAML="/tmp/local-jenkins.yaml"

# Jenkins Configuration as Code (JCasC) file where jobs and plugins will be added
JENKINS_JCASC_YAML="/var/lib/jenkins/jenkins.yaml"

# File containing the required plugins to be installed
REQUIRED_PLUGINS_FILE="/tmp/required-plugins.txt"

# List of required commands and files
REQUIRED_COMMANDS="yq grep readarray"
REQUIRED_FILES="$LOCAL_JENKINS_YAML $REQUIRED_PLUGINS_FILE"


###############################################################################
# FUNCTIONS
###############################################################################


verify_files() {
  # Ensures all required files exist
  #
  # Iterates through the list of files specified in $REQUIRED_FILES.
  # If file is missing, prints an error message and exits 1.

  for file in $REQUIRED_FILES; do
    if [[ ! -f "$file" ]]; then
      echo "Error: Required file '$file' not found." >&2
      exit 1
    fi
  done
}
 

check_dependencies() {
  # Ensures all required commands are available
  #
  # Iterates through the list of commands specified in $REQUIRED_COMMANDS.
  # If any command is missing, prints an error message and exits 1.

  for cmd in $REQUIRED_COMMANDS; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "Error: Required command '$cmd' is not installed." >&2
      exit 1
    fi
  done
}


process_plugins() {
  # Merges required plugins with local Jenkins plugin configuration
  #
  # Extracts the plugin list from $LOCAL_JENKINS_YAML into $PLUGIN_FILE.
  # For each plugin listed in $REQUIRED_PLUGINS_FILE:
  #   - If already defined in $PLUGIN_FILE, prints a warning.
  #   - If not, adds the plugin to the install list.

  # Temporary file to store extracted plugin list
  PLUGIN_FILE="/tmp/plugins.txt"

  # Extract plugins from local Jenkins YAML
  yq -r '.plugins[]' "$LOCAL_JENKINS_YAML" > "$PLUGIN_FILE"

  # Read required plugins
  readarray -t required_plugins < "$REQUIRED_PLUGINS_FILE"

  for plugin in "${required_plugins[@]}"; do
    plugin_name="${plugin%%:*}"

    if grep -q "^$plugin_name" "$PLUGIN_FILE"; then
      echo "WARNING: Plugin '$plugin_name' is already defined in $LOCAL_JENKINS_YAML."
      echo "WARNING: This overrides default plugin management. Proceed with caution."
    else
      echo "Adding required plugin '$plugin' to install list."
      echo "$plugin" >> "$PLUGIN_FILE"
    fi
  done
}


process_jobs() {
  # Adds pipeline jobs to Jenkins configuration
  #
  # Reads job definitions (name and file) from $LOCAL_JENKINS_YAML.
  # For each job:
  #   - Generates a pipeline job script block.
  #   - Appends the block to the .jobs array in $JENKINS_JCASC_YAML using yq.

  yq -r '.jobs[] | "\(.name) \(.file)"' $LOCAL_JENKINS_YAML |
  while read -r name file; do
    yq -y -i "
      .jobs += [{
        script: \"pipelineJob('$name') {
          theScript = new File('/mnt/local-project/$file').getText('UTF-8')
          definition {
            cps {
              script(theScript)
              sandbox()
            }
          }
        }\"
      }]
    " "$JENKINS_JCASC_YAML"
  done 
}


###############################################################################
# MAIN
# Runs all major setup steps in order:
#   - Checks for required commands
#   - Verifies necessary files exist
#   - Processes plugin configuration
#   - Processes job definitions
###############################################################################

main() {
  check_dependencies
  verify_files
  process_plugins
  process_jobs
}


# Run the main function
main "$@"