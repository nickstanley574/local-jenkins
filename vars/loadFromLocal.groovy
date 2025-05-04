#!/usr/bin/env groovy
def call(String specificFile = '') {
    if (specificFile?.trim()) {
        // Copy only the specific file
        sh(
            label: "Copy Specific File to Workspace",
            script: """
                cd /mnt/local-project/
                
                # Ensure file exists
                if [ ! -f "${specificFile}" ]; then
                    echo "ERROR: File '${specificFile}' not found."
                    exit 1
                fi

                # Create parent directories if necessary
                mkdir -p \$(dirname "${env.WORKSPACE}/${specificFile}")

                cp --parents "${specificFile}" "${env.WORKSPACE}/"

                cd ${env.WORKSPACE}
                ls -al
            """
        )
    } else {
        // Default behavior: copy all non-ignored Git files
        sh(
            label: "Load Local Project into Workspace",
            script: """
                cd /mnt/local-project/

                # Get the list of non-ignored files
                file_list=\$(git ls-files --cached --others --exclude-standard)

                # Save to temp file
                temp_file=\$(mktemp)
                echo "\$file_list" > "\$temp_file"

                # Rsync files to workspace
                rsync -a --no-group --no-owner --files-from="\$temp_file" ./ ${env.WORKSPACE}

                cd ${env.WORKSPACE}
                ls -al
            """
        )
    }
}
