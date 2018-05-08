require "test_helper"

class GithubProxyTest < Minitest::Test

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

  def test_contents
    github = GithubProxy.new("repo", "pr1", "token")
    octomock = MiniTest::Mock.new

    octomock.expect(:contents, "CONTENT", ["repo", { path: "path", branch: "heads/branch" }])

    github.stub(:client, octomock) do
      assert_equal "CONTENT", github.contents("path", "branch")
      octomock.verify
    end
  end

  def test_file_last_update_at
    github = GithubProxy.new("repo", "pr1", "token")
    octomock = MiniTest::Mock.new

    commits = [
      {
        commit: {
          committer: {
            date: "SOME_DATE"
          }
        }
      }
    ]
    octomock.expect(:commits, commits, ["repo", "branch", { path: "path" }])

    github.stub(:client, octomock) do
      assert_equal "SOME_DATE", github.file_last_update_at("path", "branch")
      octomock.verify
    end
  end

  def test_create_commit
    github = GithubProxy.new("repo", "pr1", "token")
    octomock = MiniTest::Mock.new

    ref_mock = mock(object: mock(sha: "SHA_LATEST_COMMIT"))
    octomock.expect(:ref, ref_mock, ["repo", "heads/branch"])

    commit_mock = mock(commit: mock(tree: mock(sha: "SHA_BASE_TREE")))
    octomock.expect(:commit, commit_mock, ["repo", "SHA_LATEST_COMMIT"])

    octomock.expect(:create_blob, "BLOB_SHA", ["repo", Base64.encode64("content"), "base64"])

    tree_mock = mock(sha: "SHA_NEW_TREE")
    tree_info =                                         {
      :path => "filename",
      :mode => "100644",
      :type => "blob",
      :sha => "BLOB_SHA"
    }
    octomock.expect(:create_tree, tree_mock, ["repo", [tree_info], { base_tree: "SHA_BASE_TREE" }])

    commit_mock = mock(sha: "SHA_NEW_COMMIT")
    octomock.expect(:create_commit, commit_mock, ["repo", "message", "SHA_NEW_TREE", "SHA_LATEST_COMMIT"])

    octomock.expect(:update_ref, nil, ["repo", "heads/branch", "SHA_NEW_COMMIT"])

    github.stub(:client, octomock) do
      github.create_commit("message", "filename", "content", "branch")
      octomock.verify
    end
  end

  def test_create_pull_request
    github = GithubProxy.new("repo", "pr1", "token")
    octomock = MiniTest::Mock.new

    octomock.expect(:create_pull_request, nil, ["repo", "branch1", "branch2", "title", "body"])

    github.stub(:client, octomock) do
      github.create_pull_request("branch1", "branch2", "title", "body")
      octomock.verify
    end
  end

  def test_pull_request_open?
    github = GithubProxy.new("repo", "pr1", "token")
    octomock = MiniTest::Mock.new

    branches_json = [
      {
        head: {ref: "branch_not_it"},
        base: {ref: "branch1"},
        number: 1
      },
      {
        head: {ref: "branch2"},
        base: {ref: "branch_not_it"},
        number: 2
      },
      {
        head: {ref: "branch2"},
        base: {ref: "branch1"},
        number: 3
      }
    ]

    octomock.expect(:pull_requests, branches_json, ["repo", state: "open"])
    octomock.expect(:pull_requests, branches_json, ["repo", state: "open"])

    github.stub(:client, octomock) do
      assert github.pull_request_open?("branch1", "branch2")
      assert !github.pull_request_open?("branch1", "branch3")
      octomock.verify
    end
  end
end
