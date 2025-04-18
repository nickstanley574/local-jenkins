FROM jenkins/jenkins:lts

# Switch to root user to install additional tools
USER root

RUN apt-get update && \
    apt-get install -y \
    vim \
    inotify-tools \
    acl \
    sudo \
    yq

RUN echo "jenkins ALL=(ALL) NOPASSWD: /usr/bin/setfacl -m u\\:jenkins\\:rw- /var/run/docker.sock" >> /etc/sudoers

USER jenkins

# Skip initial setup wizard and Allow local checkout (INSECURE SETTING APPLIED)
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false -Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true

# Set initial admin password
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY settings.groovy /usr/share/jenkins/ref/init.groovy.d/

COPY --from=projectsource local-jenkins.yaml /tmp/local-jenkins.yaml
COPY --chown=jenkins jenkins.yaml /var/lib/jenkins/jenkins.yaml
ENV CASC_JENKINS_CONFIG=/var/lib/jenkins/jenkins.yaml

COPY jenkins_config_init.sh /tmp/jenkins_config_init.sh
COPY required_plugins.txt /tmp/required_plugins.txt
RUN /tmp/jenkins_config_init.sh
RUN jenkins-plugin-cli --plugins --verbose -f /tmp/plugins.txt 2>&1 | tee

COPY entrypoint.sh .

ENTRYPOINT ["./entrypoint.sh"]