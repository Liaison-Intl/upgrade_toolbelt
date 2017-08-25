class TravisConnection
  attr_reader :github_token,
              :repo_name

  def initialize(github_token, repo_name)
    @github_token = github_token
    @repo_name = repo_name
    login
  end

  def login
    Travis::Pro.github_auth(github_token)
  end

  def listen
    Travis::Pro.listen(repo) do |stream|
      stream.on("build:finished") do |event|
        yield event
      end
    end
  end

  def clear_session
    repo.session.clear_cache
  end

  def last_complete_build(base)
    repo.builds.detect do |build|
      base_branch(build) == base && build.finished? && !build.pull_request?
    end
  end

  def base_branch(build)
    build.branch_info.match(/\A[^\s]*/).to_s
  end

  def repo
    @repo ||= Travis::Pro::Repository.find(repo_name)
  end
end
