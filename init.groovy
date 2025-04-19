#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

// Initializes Jenkins security: creates 'admin' user, sets local
// user database, and grants full access to logged-in users.

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)

instance.save()

// Enable the "Show pipeline graph on build and job pages" appearance setting globally
// https://github.com/jenkinsci/pipeline-graph-view-plugin/blob/28288510bb6db9916d573b099ac4a32e2a1f85cd/src/main/java/io/jenkins/plugins/pipelinegraphview/multipipelinegraphview/MultiPipelineGraphViewAction.java#L51

import io.jenkins.plugins.pipelinegraphview.PipelineGraphViewConfiguration;

PipelineGraphViewConfiguration.get().showGraphOnJobPage = true
PipelineGraphViewConfiguration.get().showGraphOnBuildPage = true