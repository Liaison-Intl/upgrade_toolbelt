require "test_helper"

module LogAnalyzer
  class AnalyzerTest < Minitest::Test
    def setup
      travis = mock('travis')
      travis.stubs(:clear_session)
      @logger = mock('logger')

      @analyzer = Analyzer.new(travis, "REPO", "TOKEN")
      @analyzer.stubs(:logger).returns(@logger)
    end

    def test_build_is_not_pr
      build = mock('build', pull_request?: false, number: 42)

      @logger.expects(:warn).with("Build 42 is not a pull request. Skipping.")
      @analyzer.check_build(build)
    end

    def test_build_has_no_failures
      job = mock('job', failed?: false)
      build = mock('build', pull_request?: true, jobs: [job])
      build.stubs(:pull_request_number).returns(4242)

      @logger.expects(:info).with("Analyzing PR's log: 4242")
      @analyzer.check_build(build)
    end

    def test_build_has_failures
      job = mock('job', failed?: true)
      build = mock('build', pull_request?: true, jobs: [job])
      build.stubs(:pull_request_number).returns(4242)
      build.stubs(:number).returns(42)

      github = mock('github')
      github.expects(:add_comment).once
      GithubProxy.stubs(:new).returns(github)

      @logger.expects(:info).with("Analyzing PR's log: 4242")
      @logger.expects(:info).with("Reporting Results")
      @analyzer.check_build(build)
    end
  end
end
