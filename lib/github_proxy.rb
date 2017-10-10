require "octokit"

class GithubProxy
  def initialize(repo_name, pull_request_number, github_token)
    @repo_name = repo_name
    @pull_request_number = pull_request_number
    @github_token = github_token
  end

  def client
    @client ||= Octokit::Client.new(access_token: github_token)
  end

  def add_comment(comment)
    client.add_comment(repo_name, pull_request_number, comment)
  end

  def add_labels_to_an_issue(labels)
    client.add_labels_to_an_issue(repo_name, pull_request_number, labels)
  end

  def remove_label(label)
    client.remove_label(repo_name, pull_request_number, label)
  rescue URI::InvalidURIError
    # Ignore: The pull request does not have the label to begin with.
  end

  def contents(path, branch = "master")
    client.contents(@repo_name, path: path, branch: "heads/#{branch}")
  end

  def file_last_update_at(path, branch = "master")
    client.commits(@repo_name, branch, path: path).first[:commit][:committer][:date]
  end

  def create_commit(commit_message, filename, file_content, branch)
    base64_content = Base64.encode64(file_content)
    sha_latest_commit = client.ref(@repo_name, "heads/#{branch}").object.sha
    sha_base_tree = client.commit(@repo_name, sha_latest_commit).commit.tree.sha
    blob_sha = client.create_blob(@repo_name, base64_content, "base64")
    sha_new_tree = client.create_tree(@repo_name,
                                      [
                                        {
                                          :path => filename,
                                          :mode => "100644",
                                          :type => "blob",
                                          :sha => blob_sha
                                        }
                                      ],
                                      {
                                        :base_tree => sha_base_tree
                                      }
    ).sha

    sha_new_commit = client.create_commit(@repo_name, commit_message, sha_new_tree, sha_latest_commit).sha
    client.update_ref(@repo_name, "heads/#{branch}", sha_new_commit)
  end

  def create_pull_request(merge_into_branch, merge_from_branch, title, body = nil)
    client.create_pull_request(@repo_name, merge_into_branch, merge_from_branch, title, body)
  end

  private

  attr_reader :github_token, :pull_request_number, :repo_name
end
