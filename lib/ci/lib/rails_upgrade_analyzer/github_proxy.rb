module RailsUpgradeAnalyzer
  class AuthenticationError < RuntimeError
  end

  class GithubProxy
    def self.access_token
      ENV.fetch("GITHUB_TOKEN") do
        raise AuthenticationError, "You must set GITHUB_TOKEN with a personal access token"
      end
    end

    def initialize(repo_name, pull_request_number)
      @repo_name = repo_name
      @pull_request_number = pull_request_number
    end

    def client
      @client || fail("You must login first")
    end

    def login
      @client = Octokit::Client.new(access_token: self.class.access_token)
    end

    def add_comment(comment)
      client.add_comment(repo_name, pull_request_number, comment)
    end

    def add_labels_to_an_issue(labels)
      client.add_labels_to_an_issue(repo_name, pull_request_number, labels)
    end

    def remove_label(label)
      client.remove_label(repo_name, pull_request_number, label)
    rescue
      # Ignore, it probably doesn't have the label to begin with.
    end

    private

    attr_reader :pull_request_number, :repo_name
  end
end
