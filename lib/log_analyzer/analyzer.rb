require_relative "../travis_connection"
require_relative "commenter"

module LogAnalyzer
  class Analyzer

    def initialize(travis, repo_name, github_token)
      @github_token = github_token
      @repo_name = repo_name
      @travis = travis
    end

    def check_build(build)
      unless build.pull_request?
        log "Build #{build.number} is not a pull request. Skipping."
        return
      end

      @travis.clear_session

      log "Analyzing PR's log: #{build.pull_request_number}"
      failed_job = analyze_build(build)
      report_results(build) if failed_job
    end

    private

    def analyze_build(build)
      build.jobs.detect do |job|
        job.failed?
      end
    end

    def report_results(build)
      log "Reporting Results"
      github = ::GithubProxy.new(@repo_name, build.pull_request_number, @github_token)

      report = Commenter.new(build)
      github.add_comment(report.generate)
    end

    def log(msg)
      puts "LogAnalyzer: #{msg}"
    end
  end
end
