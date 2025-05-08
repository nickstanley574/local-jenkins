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
RUN echo "jenkins ALL=(ALL) NOPASSWD: /usr/bin/setfacl -Rm u\\:jenkins\\:rwx- -Rdm u\\:jenkins\\:rwx- /var/jenkins_home/" >> /etc/sudoers

USER jenkins

# Skip initial setup wizard and Allow local checkout (INSECURE SETTING APPLIED)
ENV JAVA_OPTS='-Djenkins.install.runSetupWizard=false -Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true'

# Copy groovy startup script to the correct directory. 
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/

COPY --from=projectsource local-jenkins.yaml /tmp/local-jenkins.yaml
COPY --chown=jenkins jenkins.yaml /var/lib/jenkins/jenkins.yaml
ENV CASC_JENKINS_CONFIG=/var/lib/jenkins/jenkins.yaml

COPY bootstrap-jenkins-config.sh /tmp/bootstrap-jenkins-config.sh
COPY required-plugins.txt /tmp/required-plugins.txt

RUN /tmp/bootstrap-jenkins-config.sh
RUN jenkins-plugin-cli --plugins --verbose -f /tmp/plugins.txt 2>&1 | tee

RUN mkdir -p /var/lib/jenkins/jkl-shared-lib/vars

COPY entrypoint.sh .
COPY output.sh .

ENTRYPOINT ["./entrypoint.sh"]