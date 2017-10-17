require "test_helper"

module KnapsackAnalyzer
  class AnalyzerTest < Minitest::Test
    def setup
      @travis = mock('travis')
      @github = mock('github')
      @logger = mock('logger')

      @analyzer = Analyzer.new(@travis, "REPO", "TOKEN")
      @analyzer.stubs(:github).returns(@github)
      @analyzer.stubs(:logger).returns(@logger)
    end

    def test_build_failed
      build = mock('build', passed?: false, number: 42)

      @logger.expects(:warn).with("Build 42 did not pass. Skipping.")
      @analyzer.check_build(build)
    end

    def test_build_branch_is_not_master
      build = mock('build', passed?: true)
      @travis.expects(:base_branch).returns("base")

      @logger.expects(:warn).with("Build branch is base. Skipping.")
      @analyzer.check_build(build)
    end

    def test_knapsack_not_out_of_date
      build = mock('build', passed?: true)
      @travis.expects(:base_branch).returns("master")
      last_update = Time.now - 5
      @github.expects(:file_last_update_at).returns(last_update)

      @logger.expects(:warn).with("knapsack_minitest_report.json was last updated on #{last_update}. Skipping.")
      @analyzer.check_build(build)
    end

    def test_update_knapsack
      job_body = <<END
.... Some test data ....
      
Knapsack report was generated
{
  "test1": 10,
  "test2": 5
}
Knapsack global time execution for tests

.... Some other data ....
END

      job = mock("job", log: mock(clean_body: job_body))
      build = mock('build', passed?: true, jobs: [job])
      @travis.expects(:base_branch).returns("master")

      @github.expects(:file_last_update_at).returns(Time.new(2000,1,1))

      @logger.expects(:info).with("Let's update knapsack!")
      @analyzer.expects(:fetch_current_timings)
      @analyzer.expects(:generate_report).with(nil, { 'test1' => 10, 'test2' => 5 }, build)
      @analyzer.expects(:publish)

      @analyzer.check_build(build)
    end

    def test_knapsack_report_missing
      job_body = <<END
.... Some test data ....
      
missing knapsack data

.... Some other data ....
END

      job = mock("job", log: mock(clean_body: job_body))
      build = mock('build', passed?: true, jobs: [job])
      @travis.expects(:base_branch).returns("master")
      @github.expects(:file_last_update_at).returns(Time.new(2000,1,1))

      @logger.expects(:info).with("Let's update knapsack!")
      @analyzer.expects(:fetch_current_timings)
      @analyzer.expects(:generate_report).with(nil, {}, build)
      @analyzer.expects(:publish)

      @analyzer.check_build(build)
    end

    def test_generate_report
      job = mock("job")
      build = mock('build', passed?: true, jobs: [job], number: 42, id: 4242)
      @travis.expects(:base_branch).returns("master")
      @travis.expects(:build_url).returns("URL")
      @github.expects(:file_last_update_at).returns(Time.new(2000,1,1))

      previous_timings = {
        "test1" => 300,
        "test2" => 1500,
      }
      extracted_timings = {
        "test1" => 300,
        "test2" => 1000,
        "test3" => 150,
      }

      @analyzer.expects(:analyze_job).returns(extracted_timings)
      @logger.expects(:info).with("Let's update knapsack!")
      @analyzer.expects(:fetch_current_timings).returns(previous_timings)

      report = <<END
Travis build [#42](URL)

x | Previous | New
-|-----|---
Estimated time (s) | 1800 sec | 1450 sec
Estimated time (h) | ~0.5 hours | ~0.4 hours
Number of tests | 2 | 3

Slowest tests:
- test2 (1000 sec)
- test1 (300 sec)
- test3 (150 sec)
END
      @analyzer.expects(:publish).with(extracted_timings, build, report)

      @analyzer.check_build(build)
    end

    def test_publish
      job = mock("job")
      build = mock('build', passed?: true, jobs: [job], number: 42)
      @travis.expects(:base_branch).returns("master")
      @github.expects(:file_last_update_at).returns(Time.new(2000,1,1))

      extracted_timings = {
        "test3" => 300,
        "test2" => 1000,
        "test1" => 150,
      }

      expected_json = JSON.pretty_generate(
        {
          "test1" => 150,
          "test2" => 1000,
          "test3" => 300,
        }
      )

      @analyzer.expects(:analyze_job).returns(extracted_timings)
      @logger.expects(:info).with("Let's update knapsack!")
      @analyzer.expects(:fetch_current_timings)
      @analyzer.expects(:generate_report).returns("REPORT")

      message = "Updates knapsack_minitest_report.json from Travis build 42"
      @github.expects(:create_commit).with(message, "knapsack_minitest_report.json", expected_json, "feature/knapsack_minitest_report-update")
      @github.expects(:create_pull_request).with("master", "feature/knapsack_minitest_report-update", message, "REPORT")

      @analyzer.check_build(build)    end
  end
end
