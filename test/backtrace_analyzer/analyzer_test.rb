require 'test_helper'

module BacktraceAnalyzer
  class AnalyzerTest < Minitest::Test
    def setup
      travis = mock('travis')
      travis.stubs(:clear_session)

      @logger = mock('logger')

      @analyzer = Analyzer.new(travis, 'repo', 'token')
      @analyzer.stubs(:logger).returns(@logger)
    end

    def test_build_is_not_pr
      build = mock('build', pull_request?: false, number: 42)
      @logger.expects(:warn).with('Build 42 is not a pull request. Skipping.')
      @analyzer.check_build(build)
    end

    def test_build_does_not_have_failures
      log_body = 'This does not contain failures'

      session = mock('session')
      session.stubs(:get_raw).returns(log_body)

      log = mock('log')
      log.stubs(:session).returns(session)
      log.stubs(:id).returns(42)

      job = mock('job')
      job.stubs(:failed?).returns(true)
      job.stubs(:log).returns(log)

      build = mock('build')
      build.stubs(:pull_request?).returns(true)
      build.stubs(:pull_request_number).returns(4242)
      build.stubs(:jobs).returns([job])

      @logger.expects(:info).with('Analyzing PR: 4242')
      ::GithubProxy.expects(:new).never
      @analyzer.expects(:report_results)

      @analyzer.check_build(build)
    end

    def test_build_has_failures
      log_body = <<-BODY
        aaa
        FAILED_TEST:START
        xxx
        vendor/bundle/makes/it/so/this/line/is/ignored
        FAILED_TEST:END
        yyy
        ERROR_TEST:START
        zzz
        vendor/bundle/makes/it/so/this/line/is/ignored
        ERROR_TEST:END
        bbb
      BODY

      session = mock('session')
      session.stubs(:get_raw).returns(log_body)

      log = mock('log')
      log.stubs(:session).returns(session)
      log.stubs(:id).returns(42)

      job = mock('job')
      job.stubs(:failed?).returns(true)
      job.stubs(:log).returns(log)

      build = mock('build')
      build.stubs(:pull_request?).returns(true)
      build.stubs(:pull_request_number).returns(4242)
      build.stubs(:jobs).returns([job])

      github = mock('github')
      GithubProxy.stubs(:new).returns(github)

      @logger.expects(:info).with('Analyzing PR: 4242')
      @logger.expects(:info).with('Reporting Results')

      expected_comment = "<details>\n<summary>2 test(s) need your attention</summary>\n\n```\nxxx\n```\n```\nzzz\n```\n</details>\n"
      github.expects(:add_comment).with(expected_comment)

      @analyzer.check_build(build)
    end
  end
end
