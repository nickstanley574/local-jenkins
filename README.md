# Local Jenkins

When working on a personal project, I am often in need of a CI/CD process. While GitHub Workflows is an option, I prefer to keep some projects private and avoid the costs of running Workflows in private repos. This project is my solution for that need, a local Jenkins designed to run my projects out of the box. This approach allows for the execution of my project CI/CD in an isolated environment, maintaining package version consistency, and closely replicating the production runtime environment. Essentially, I am taking advantage of the purpose and promise of containers.

## Quick Start

There 2 environment variables that can be set, if they are not set they have default to allow this process to run out of the box.

* `LOCAL_JENKINS_PORT` (default: 8080) - The local port to map the Jenkins container port to.
* `LOCAL_JENKINS_ALLOW_ROOTLESS` (default: false) - If your local docker install is not running in [rootless mode](https://docs.docker.com/engine/security/rootless/) the container will fail to start by default. Set `LOCAL_JENKINS_ALLOW_ROOTLESS` value to `true` if you would like to override this behavior.


From the top level of the project directory that which contains the `Jenkinsfile` run:

```
cd ./local-jenkins
./run-local.jenkins.sh
```

At this point your should be able to access the jenins instance at `http://localhost:8080/` and you should see a job with the same name as the project folder directory. 

## Desgin Details

### Docker In Docker 

Running Jenkins in a container allows it to be isolated from the local system, but in order for the Jenkins container to run other containers I wanted to use the host's docker engine. When a container is started up it called via the container to the local docker bin and docker socket via volume mounting. The advantage of this is for debugging you can run `docker` command from your command line to see what is running and `exec` into running container started by Jenkins if needed. 

Since I run docker in [rootless mode](https://docs.docker.com/engine/security/rootless/), which I think should be the standard practice, there is a permissions issues between the container `jenkins` user and the local permissions of the docker socket. The jenkins user doesn't have the needed permissions to the `docker.sock` and if the host `docker.sock` permissions are updated it could affect the host. This problem could be solved by running the Jenkins container Jenkins process as `root`, but using root should alway be questioned. 

The solution was to use [Linux Access Control Lists (ACLs)](https://www.redhat.com/sysadmin/linux-access-control-lists) on the container and setup during the docker build while the build was still running as `root` to install `acl` and provided a config that tells the container that the `jenkins` user can access the `docker.sock`. The trick is that since the docker.sock file is not in the image itself and is amount the image build provided a `/etc/sudoers` configs to allow the `jenkins` user to `sudo setfacl` the `docker.sock` file. Since the acl config is isolated to the container it doesn't affect permissions on the host.

### Getting the Code to Jenkins

Most Jenkins jobs I have encountered pull their Jenkinsfile from a external git repo. Since I want to run the code I have locally to test changes to both the code and the Jenkinsfile itself before committing this isn't a option. I don't want to have do the full git commit flow and pull just because I missed a comma in a Jenkinsfile during init development. Additionally, When using a Jenkinsfile, changes are only applied after another job run, a known limitation documented in Stack Overflow and Jenkins project tickets.

- [How to make sure list of parameters are updated before running a Jenkins pipeline?- stackoverflow.com](https://stackoverflow.com/questions/46680573/how-to-make-sure-list-of-parameters-are-updated-before-running-a-jenkins-pipelin)
- [How to force jenkins to reload a jenkinsfile? - stackoverflow.com](https://stackoverflow.com/questions/44422691/how-to-force-jenkins-to-reload-a-jenkinsfile)
- [JENKINS-50365 Reload pipeline script without executing the job](https://issues.jenkins.io/browse/JENKINS-50365)

In the past, I have addressed this by using a 'refresh' parameter that skips all the stages when selected, but that approach is clunky and prone to errors.

To solve this I used the Jenkins Configuration as Code Plugin which allows you to load in [`pipelineJob`](https://jenkinsci.github.io/job-dsl-plugin/#path/pipelineJob) based on a script location. This combined with mounting the project directory to the jenkins docker container allowed for a file watcher to trigger the `jenkins-cli.jar` command `reload-jcasc-configuration` to reload the configs on `Jenkinsfile` changes within the `entrypoint.sh` of the Docker image. This ensures that when a build is run it is the same configs that is in the Jenkinsfile.

### Insecure Settings

Since this is running locally, I've adjusted security settings for simplicity of use, akin to local development where you have access to admin settings for the applications and databases. For example, at start up a password in needed for the admin user which is `admin:admin` after the init config I remove the need to any authenticated login via `authorizationStrategy: unsecured`. This unsecured setting are comment with reasoning when applied.

### Limitations and Possible Future improvements

My current design has limitations as it was tailored for my personal project's specific needs. The main improvement I would like to make in the near future is currently, only one job can be configured for a project. There is a use case from a project to have more than one job for different workflows.

A better installation method. Currently, I am cloning the project into my other project and ensuring that the "local-jenkins" folder is included in the gitignore file. While this approach has meet my needs so far, it is not ideal and could potentially lead to issues.

## Final Thoughts

This project serves as a good example of how many seemingly simple solutions are, in fact, a specific combination of specific features across many tools, achieved by research and experimentation, ultimately leading to the desired outcome. 