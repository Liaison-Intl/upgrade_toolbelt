require "test_helper"

class TestGithubProxy < MiniTest::Unit::TestCase

  def test_raises_error_if_token_not_set
    set_variable("GITHUB_TOKEN", nil) do
      github = RailsUpgradeAnalyzer::GithubProxy.new("repo", "pr1")
      assert_raises(RailsUpgradeAnalyzer::AuthenticationError) { github.login }
    end
  end

  def test_add_comment
    github = RailsUpgradeAnalyzer::GithubProxy.new("repo", "pr1")
    octomock = MiniTest::Mock.new

    octomock.expect(:add_comment, nil, ["repo", "pr1", "comment"])

    github.stub(:client, octomock) do
      github.add_comment("comment")
      octomock.verify
    end
  end

  def test_add_labels_to_an_issue
    github = RailsUpgradeAnalyzer::GithubProxy.new("repo", "pr1")
    octomock = MiniTest::Mock.new

    octomock.expect(:add_labels_to_an_issue, nil, ["repo", "pr1", ["label"]])

    github.stub(:client, octomock) do
      github.add_labels_to_an_issue(["label"])
      octomock.verify
    end
  end

  def test_remove_label
    github = RailsUpgradeAnalyzer::GithubProxy.new("repo", "pr1")
    octomock = MiniTest::Mock.new

    octomock.expect(:remove_label, nil, ["repo", "pr1", "label"])

    github.stub(:client, octomock) do
      github.remove_label("label")
      octomock.verify
    end
  end

  def set_variable(name, value)
    value_was = ENV[name]
    ENV[name] = value
    yield
  ensure
    ENV[name] = value_was
  end
end
