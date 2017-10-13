require "base64"
require 'json'
require_relative "../travis_connection"

module KnapsackAnalyzer
  class Analyzer

    def initialize(travis, repo_name, github_token)
      @github_token = github_token
      @repo_name = repo_name
      @travis = travis
      @knapsack_branch = "feature/knapsack_minitest_report-update"
      @knapsack_file_path = "knapsack_minitest_report.json"
    end

    def check_build(build)
      unless build.passed?
        log "Build #{build.number} did not pass. Skipping."
        return
      end

      if master_branch?(build) and knapsack_out_of_date?
        log "Let's update knapsack!"

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
        log(e.message)
      end
    end

    def analyze_job(job)
      raw_json_text = nil
      body = job.log.clean_body
      body.split("\n").each do |line|
        if line.match(/^Knapsack global time execution for tests/)
          break
        end
        if raw_json_text
          raw_json_text << line
        end
        if line.match(/^Knapsack report was generated/)
          raw_json_text = []
        end
      end
      if raw_json_text.nil?
        {}
      else
        JSON.parse(raw_json_text.join)
      end
    end

    def github
      ::GithubProxy.new(@repo_name, nil, @github_token)
    end

    def knapsack_out_of_date?
      two_weeks_ago = Time.now - 1209600 # 14 days in seconds
      last_update = github.file_last_update_at(@knapsack_file_path, "heads/#{@knapsack_branch}")
      if last_update > two_weeks_ago
        log("#{@knapsack_file_path} was last updated on #{last_update.localtime}. Skipping.")
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
        log("Build branch is #{base}. Skipping.")
      end
    end

    def log(msg)
      puts "KnapsackAnalyzer: #{msg}"
    end
  end
end
