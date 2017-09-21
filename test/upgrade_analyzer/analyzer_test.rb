require "test_helper"

module UpgradeAnalyzer
  class AnalyzerTest < MiniTest::Unit::TestCase
    def setup
      last_build = mock('last_build')
      last_build.stubs(:jobs).returns([])

      travis = mock('travis')
      travis.stubs(:clear_session)
      travis.stubs(:base_branch).returns("base")
      travis.stubs(:last_complete_build).returns(last_build)
      travis.stubs(:job_url).returns("URL")

      @analyzer = Analyzer.new(travis, "REPO", "TOKEN")
    end

    def test_build_is_not_pr
      build = mock('build', pull_request?: false, number: 42)
      @analyzer.expects(:log).with("Build 42 is not a pull request. Skipping.")
      @analyzer.check_build(build)
    end

    def test_job_is_not_allowed_failure
      job = mock('job', allow_failure?: false)

      build = mock('build', pull_request?: true, jobs: [job])
      build.stubs(:pull_request_number).returns(4242)

      @analyzer.expects(:log).with("Analyzing PR: 4242")
      @analyzer.expects(:log).with("Getting results for base branch")
      @analyzer.expects(:report_results)
      @analyzer.check_build(build)
    end

    def test_report_errors
      job_body = "267 tests, 266 passed, 1 failures, 0 errors, 0 skips, 1798 assertions"

      job = mock('job', id: 4242, allow_failure?: true)
      job.stubs(:number).returns(42)
      job.expects(:log).returns(mock(clean_body: job_body))

      build = mock('build', pull_request?: true, jobs: [job])
      build.stubs(:pull_request_number).returns(4242)

      github = mock('github')
      github.expects(:remove_label).times(3)
      github.expects(:add_comment).with("Upgrade Status: errors")
      github.expects(:add_labels_to_an_issue).with(["[Upgrade] CI Needed (rebase base branch)"])
      GithubProxy.stubs(:new).returns(github)

      @analyzer.expects(:log).with("Analyzing PR: 4242")
      @analyzer.expects(:log).with("Getting results for base branch")
      @analyzer.expects(:log).with("Analyzing job: 42")
      @analyzer.expects(:log).with("Reporting Results")
      @analyzer.expects(:validate_comparison).returns([:errors])
      @analyzer.check_build(build)
    end

    def test_report_add_label
      build = mock('build', pull_request?: true, jobs: [])
      build.stubs(:pull_request_number).returns(4242)

      github = mock('github')
      github.expects(:remove_label).times(3)
      github.expects(:add_labels_to_an_issue).with(["[Upgrade] Accepted"])
      GithubProxy.stubs(:new).returns(github)

      @analyzer.expects(:log).with("Analyzing PR: 4242")
      @analyzer.expects(:log).with("Getting results for base branch")
      @analyzer.expects(:log).with("Reporting Results")
      @analyzer.check_build(build)
    end

    def test_report_comments_and_label
      build = mock('build', pull_request?: true)
      build.stubs(:pull_request_number).returns(4242)

      github = mock('github')
      github.expects(:remove_label).times(3)
      github.expects(:add_labels_to_an_issue).with(["[Upgrade] Accepted"])
      github.expects(:add_comment)
      GithubProxy.stubs(:new).returns(github)

      result = mock('result')
      result.expects(:tests).returns(5).twice
      result.expects(:passed).returns(4).twice
      result.expects(:failures).returns(3).twice
      result.expects(:errors).returns(2).twice
      result.expects(:passing_percent).returns("10%").twice
      result.stubs(:deprecations).returns({})
      result.stubs(:deprecation_count).returns(0)
      result.stubs(:description).returns("DESCRIPTION")

      base_result = mock('base_result', job_number: 42)
      base_result.expects(:tests).returns(5).twice
      base_result.expects(:passed).returns(4).twice
      base_result.expects(:failures).returns(3).twice
      base_result.expects(:errors).returns(2).twice
      base_result.expects(:passing_percent).returns("10%").twice
      base_result.stubs(:deprecations).returns({})
      base_result.stubs(:description).returns("DESCRIPTION")

      @analyzer.expects(:analyze_build).returns([result])
      @analyzer.expects(:analyze_build).returns([base_result])
      @analyzer.expects(:log).with("Analyzing PR: 4242")
      @analyzer.expects(:log).with("Getting results for base branch")
      @analyzer.expects(:log).with("Reporting Results")
      @analyzer.expects(:validate_comparison).returns([])
      @analyzer.check_build(build)
    end
  end
end
