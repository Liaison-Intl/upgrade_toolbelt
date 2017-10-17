require "base64"
require 'json'

require_relative "../base_analyzer"
require_relative "../travis_connection"

module KnapsackAnalyzer
  class Analyzer < ::BaseAnalyzer

    def initialize(travis, repo_name, github_token)
      super(travis, repo_name, github_token)
      @knapsack_branch = "feature/knapsack_minitest_report-update"
      @knapsack_file_path = "knapsack_minitest_report.json"

      @ruby_regexp = /Running (Ruby .*)/
      @rails_regexp = /Running (Rails .*)/
      @knapsack_start = /^Knapsack report was generated/
      @knapsack_end = /^Knapsack global time execution for tests/

      @knapsack_rails_match = /Rails 3.1/
    end

    def check_build(build)
      unless build.passed?
        logger.warn "Build #{build.number} did not pass. Skipping."
        return
      end

      if master_branch?(build) and knapsack_out_of_date?
        logger.info "Let's update knapsack!"

        previous_timings = fetch_current_timings

        extracted_timings = {}
        build.jobs.each do |job|
          extracted_timings.merge!(analyze_job(job))
        end

        report = generate_report(previous_timings, extracted_timings, build)
        publish(extracted_timings, build, report)
      end
    end

    private

    def fetch_current_timings
      knapsack_content = github.contents(@knapsack_file_path, @knapsack_branch)
      decoded_content = Base64::decode64(knapsack_content[:content])
      JSON.parse(decoded_content)
    end

    def generate_report(current_timings, new_timings, build)
      cur_est_time = current_timings.values.inject(0) {|sum, i| sum+=i }
      cur_est_sec = "%d sec" % (cur_est_time)
      cur_est_hrs = "%.1f hours" % (cur_est_time/60.0/60)
      cur_nb_test = current_timings.keys.size
      new_est_time = new_timings.values.inject(0) {|sum, i| sum+=i }
      new_est_sec = "%d sec" % (new_est_time)
      new_est_hrs = "%.1f hours" % (new_est_time/60.0/60)
      new_nb_test = new_timings.keys.size

      build_link = "[##{build.number}](#{@travis.build_url(build.id)})"

      report =<<EOF
Travis build #{build_link}

x | Previous | New
-|-----|---
Estimated time (s) | #{cur_est_sec} | #{new_est_sec}
Estimated time (h) | ~#{cur_est_hrs} | ~#{new_est_hrs}
Number of tests | #{cur_nb_test} | #{new_nb_test}

Slowest tests:
EOF
      new_timings.sort_by(&:last).reverse.first(3).each do |test, time|
        report << "- #{test} (#{time.to_i} sec)\n"
      end
      report
    end

    def publish(timings_hash, build, report)
      reordered_timing_hash = {}
      timings_hash.sort_by(&:first).each do |k,v|
        reordered_timing_hash[k] = v
      end

      file_content = JSON.pretty_generate(reordered_timing_hash)
      commit_message = "Updates #{@knapsack_file_path} from Travis build #{build.number}"
      begin
        github.create_commit(commit_message, @knapsack_file_path, file_content, @knapsack_branch)
        github.create_pull_request("master", @knapsack_branch, commit_message, report)
      rescue Octokit::UnprocessableEntity => e
        logger.error(e.message)
      end
    end

    def analyze_job(job)
      raw_json_text = nil
      body = job.log.clean_body
      body.split("\n").each do |line|
        if m = line.match(@rails_regexp)
          unless m[1].match(@knapsack_rails_match)
            return {}
          end
        end

        if raw_json_text and line.match(@knapsack_end)
          return JSON.parse(raw_json_text.join)
        end
        if raw_json_text
          raw_json_text << line
        elsif line.match(@knapsack_start)
          raw_json_text = []
        end
      end

      {}
    end

    def github
      ::GithubProxy.new(@repo_name, nil, @github_token)
    end

    def knapsack_out_of_date?
      two_weeks_ago = Time.now - 1209600 # 14 days in seconds
      last_update = github.file_last_update_at(@knapsack_file_path, "heads/#{@knapsack_branch}")
      if last_update > two_weeks_ago
        logger.warn("#{@knapsack_file_path} was last updated on #{last_update.localtime}. Skipping.")
        false
      else
        true
      end
    end

    def master_branch?(build)
      base = @travis.base_branch(build)
      if base == "master"
        true
      else
        logger.warn("Build branch is #{base}. Skipping.")
      end
    end
  end
end
