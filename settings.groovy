
// https://github.com/jenkinsci/pipeline-graph-view-plugin/blob/28288510bb6db9916d573b099ac4a32e2a1f85cd/src/main/java/io/jenkins/plugins/pipelinegraphview/multipipelinegraphview/MultiPipelineGraphViewAction.java#L51

// Enable the "Show pipeline graph on build and job pages" appearance setting globally
import io.jenkins.plugins.pipelinegraphview.PipelineGraphViewConfiguration;
PipelineGraphViewConfiguration.get().showGraphOnJobPage = true
PipelineGraphViewConfiguration.get().showGraphOnBuildPage = true