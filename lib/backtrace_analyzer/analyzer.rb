module BacktraceAnalyzer
  class Analyzer < ::BaseAnalyzer
    def check_build(build)
      unless build.pull_request?
        logger.warn "Build #{build.number} is not a pull request. Skipping."
        return
      end

      @travis.clear_session

      logger.info "Analyzing PR: #{build.pull_request_number}"
      failures = analyze_build(build)
      report_results(build, failures)
    end

    private

    def analyze_build(build)
      failed_jobs(build).map do |job|
        extract_backtraces(job.log)
      end.compact
    end

    def extract_backtraces(log)
      body = log.session.get_raw("/logs/#{log.id}")
      failures = body.scan(/FAILED_TEST:START(.*?)FAILED_TEST:END/m)
      errors = body.scan(/ERROR_TEST:START(.*?)ERROR_TEST:END/m)
      (failures + errors).flatten
    end

    def failed_jobs(build)
      build.jobs.select(&:failed?)
    end

    def report_results(build, failures)
      return unless failures.any?

      logger.info 'Reporting Results'
      github = ::GithubProxy.new(@repo_name, build.pull_request_number, @github_token)

      comment = failures.flatten.map do |backtrace|
        trace = backtrace.scan(/^(((?!vendor\/bundle).)*)$/).join
        trace = trace.strip.gsub(/[ ]{2,}/, "").gsub("\r\r", "\r")
        ['```', trace, '```'].join("\n")
      end.join("\n")

      github.add_comment(comment)
    end
  end
end
