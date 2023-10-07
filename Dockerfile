FROM jenkins/jenkins:lts

# Switch to root user to install additional tools
USER root

RUN apt-get update && \
    apt-get install -y \
    vim \
    inotify-tools \
    acl \
    sudo

RUN echo "jenkins ALL=(ALL) NOPASSWD: /usr/bin/setfacl -m u\\:jenkins\\:rw- /var/run/docker.sock" >> /etc/sudoers

USER jenkins

# Skip initial setup wizard and Allow local checkout (INSECURE SETTING APPLIED)
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false -Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true

# Set initial admin password
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/

# Install plugins
RUN jenkins-plugin-cli --plugins \
"workflow-aggregator:latest \
pipeline-stage-view:latest \
pipeline-graph-view \
configuration-as-code:latest \
job-dsl:latest \
git:latest \
docker-plugin:latest \
docker-workflow:latest \
ansicolor:latest"

COPY jenkins.yaml /var/lib/jenkins/jenkins.yaml

ENV CASC_JENKINS_CONFIG=/var/lib/jenkins/jenkins.yaml

COPY entrypoint.sh .

ENTRYPOINT ["./entrypoint.sh"]