module UpgradeAnalyzer
  class AuthenticationError < RuntimeError
  end

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

    private

    attr_reader :github_token, :pull_request_number, :repo_name
  end
end
