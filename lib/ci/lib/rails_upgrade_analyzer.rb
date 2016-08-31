require "octokit"
require "travis"

$LOAD_PATH.unshift(File.dirname(__FILE__))

module RailsUpgradeAnalyzer
  autoload :AuthenticationError, "rails_upgrade_analyzer/github_proxy"
  autoload :GithubProxy, "rails_upgrade_analyzer/github_proxy"
  autoload :JobResult, "rails_upgrade_analyzer/job_result"
  autoload :ResultReporter, "rails_upgrade_analyzer/result_reporter"
end
