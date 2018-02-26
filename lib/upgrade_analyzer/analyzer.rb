require "stringio"

require_relative "../base_analyzer"
require_relative "../travis_connection"
require_relative "../deprecation_summary"
require_relative "../github_proxy"
require_relative "job_result"
require_relative "result_reporter"

module UpgradeAnalyzer
  class Analyzer < ::BaseAnalyzer

    UPGRADE_ACCEPTED = "[Upgrade] Accepted"
    UPGRADE_REJECTED = "[Upgrade] Rejected"
    UPGRADE_REBASE = "[Upgrade] CI Needed (rebase base branch)"
    UPGRADE_WARNING = "[Upgrade] Check Deprecation Warnings"

    def check_build(build)
      unless build.pull_request?
        logger.warn "Build #{build.number} is not a pull request. Skipping."
        return
      end

      @travis.clear_session

      logger.info "Analyzing PR: #{build.pull_request_number}"
      results = analyze_build(build, "current")
      logger.info "Getting results for base branch"
      base = @travis.base_branch(build)
      base_results = analyze_build(@travis.last_complete_build(base), base)
      report_results(build, results, base_results)
    end

    private

    def analyze_build(build, name)
      build.jobs.map do |job|
        next unless job.allow_failure?
        analyze_job(job, name)
      end.compact
    end

    def analyze_job(job, name)
      logger.info "Analyzing job: #{job.number}"
      link = "<a href='#{@travis.job_url(job.id)}'>#{name}</a>"
      body = job.log.clean_body
      match = body.match(/(?<tests>\d+) tests, (?<passed>\d+) passed, (?<failures>\d+) failures, (?<errors>\d+) errors/)
      return unless match

      summary = DeprecationSummary.new(StringIO.new(body).readlines)
      JobResult.new(job.number,
                    description: link,
                    tests: match[:tests],
                    passed: match[:passed],
                    failures: match[:failures],
                    errors: match[:errors],
                    deprecations: summary.deprecations)
    end

    def report_results(build, results, base_results)
      logger.info "Reporting Results"
      github = ::GithubProxy.new(@repo_name, build.pull_request_number, @github_token)

      remove_labels(github)

      errors = validate_comparison(results, base_results)

      if errors.any?
        report_invalid_comparison(github, errors)
      else
        if results.any?
          reports = get_reports(build, results, base_results)
          add_comment_and_labels(reports, github)
        else
          github.add_labels_to_an_issue([UPGRADE_ACCEPTED])
        end
      end
    end

    def add_comment_and_labels(reports, github)
      comment = StringIO.new
      comment << "<h1>Upgrade Build Results</h1>"

      reports.each do |report|
        comment << report.report
      end

      overall = reports.last

      if overall.deprecation_warnings_changed?
        github.add_labels_to_an_issue([UPGRADE_WARNING])
      end

      if overall.failed?
        github.add_labels_to_an_issue([UPGRADE_REJECTED])
      else
        github.add_labels_to_an_issue([UPGRADE_ACCEPTED])
      end

      github.add_comment(comment.string)
    end

    def get_reports(build, results, base_results)
      reports = []
      overall_base_result = JobResult.new("Overall", description: @travis.base_branch(build))
      overall_feature_result = JobResult.new("Overall", description: "current")

      results.each_with_index do |result, index|
        base_result = base_results[index]

        overall_base_result << base_result
        overall_feature_result << result

        reports << ResultReporter.new(base_result, result)
      end
      reports << ResultReporter.new(overall_base_result, overall_feature_result)
    end

    def remove_labels(github)
      github.remove_label(UPGRADE_ACCEPTED)
      github.remove_label(UPGRADE_REJECTED)
      github.remove_label(UPGRADE_REBASE)
    end

    def validate_comparison(results, base_results)
      errors = []
      if results.length != base_results.length
        base_ids = base_results.map(&:job_number).sort.join(", ")
        new_ids = results.map(&:job_number).sort.join(", ")
        errors << "The Base jobs do not match the jobs in the pull request."
        errors << "Base jobs: #{base_ids}"
        errors << "PR jobs:" + "&nbsp;" * 5 + new_ids
      end
      errors
    end

    def report_invalid_comparison(github, errors)
      github.add_comment("Upgrade Status: #{errors.join("<br />")}")
      github.add_labels_to_an_issue([UPGRADE_REBASE])
    end
  end
end
