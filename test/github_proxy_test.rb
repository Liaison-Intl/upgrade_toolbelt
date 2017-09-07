require "test_helper"

class GithubProxyTest < MiniTest::Unit::TestCase

  def test_add_comment
    github = GithubProxy.new("repo", "pr1", "token")
    octomock = MiniTest::Mock.new

    octomock.expect(:add_comment, nil, ["repo", "pr1", "comment"])

    github.stub(:client, octomock) do
      github.add_comment("comment")
      octomock.verify
    end
  end

  def test_add_labels_to_an_issue
    github = GithubProxy.new("repo", "pr1", "token")
    octomock = MiniTest::Mock.new

    octomock.expect(:add_labels_to_an_issue, nil, ["repo", "pr1", ["label"]])

    github.stub(:client, octomock) do
      github.add_labels_to_an_issue(["label"])
      octomock.verify
    end
  end

  def test_remove_label
    github = GithubProxy.new("repo", "pr1", "token")
    octomock = MiniTest::Mock.new

    octomock.expect(:remove_label, nil, ["repo", "pr1", "label"])

    github.stub(:client, octomock) do
      github.remove_label("label")
      octomock.verify
    end
  end
end
