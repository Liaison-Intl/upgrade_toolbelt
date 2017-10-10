require "test_helper"

class TravisConnectionTest < Minitest::Test
  def setup
    Travis::Pro.expects(:github_auth).with("TOKEN")
    @tc = TravisConnection.new("TOKEN", "REPO")
  end

  def test_listen
    mock_repo = mock()
    mock_stream = mock()
    mock_event = mock()

    @tc.expects(:repo).returns(mock_repo)
    Travis::Pro.expects(:listen).yields(mock_stream)
    mock_stream.expects(:on).yields(mock_event)

    @tc.listen do |event|
      assert_equal mock_event, event
    end
  end

  def test_clear_session
    mock_repo = mock()
    mock_session = mock()
    @tc.expects(:repo).returns(mock_repo)

    mock_repo.expects(:session).returns(mock_session)
    mock_session.expects(:clear_cache)

    @tc.clear_session
  end

  def test_last_complete_build
    mock_base_cirun_finished = mock(finished?: true, pull_request?: false, branch_info: "base")

    mock_base_pr_finished = mock(finished?: true, pull_request?: true, branch_info: "base")
    mock_base_cirun_unfinished = mock(finished?: false, branch_info: "base")

    mock_unbase_cirun_finished = mock(branch_info: "unbase")

    mock_repo = mock(builds: [
      mock_unbase_cirun_finished,
      mock_base_cirun_unfinished,
      mock_base_pr_finished,
      mock_base_cirun_finished,
    ])

    @tc.expects(:repo).returns(mock_repo)

    assert_equal mock_base_cirun_finished, @tc.last_complete_build("base")
  end

  def test_base_branch
    mock_base_cirun_finished = mock(branch_info: "base")
    assert_equal "base", @tc.base_branch(mock_base_cirun_finished)
  end

  def test_repo
    mock_repo = mock()
    Travis::Pro::Repository.expects(:find).with("REPO").returns(mock_repo)
    assert_equal mock_repo, @tc.repo
  end

  def test_job_url
    assert_equal "https://travis-ci.com/REPO/jobs/42", @tc.job_url(42)
  end
end
