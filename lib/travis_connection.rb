class TravisConnection
  def initialize(github_token, repo_name)
    @github_token = github_token
    @repo_name = repo_name
    login
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
      # puts "\e[32m" + "base_branch(build)=#{(base_branch(build)).inspect}" + "\e[39m"
      # puts "\e[32m" + "build.finished?=#{(build.finished?).inspect}" + "\e[39m"
      # puts "\e[32m" + "build.pull_request?=#{(build.pull_request?).inspect}" + "\e[39m"

      base_branch(build) == base && build.finished? && !build.pull_request?
    end
  end

  def base_branch(build)
    build.branch_info.match(/\A[^\s]*/).to_s
  end

  def repo
    @repo ||= Travis::Pro::Repository.find(@repo_name)
  end

  def job_url(job_id)
    "https://travis-ci.com/#{@repo_name}/jobs/#{job_id}"
  end

  private
  def login
    Travis::Pro.github_auth(@github_token)
  end
end
