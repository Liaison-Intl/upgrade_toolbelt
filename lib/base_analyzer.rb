class BaseAnalyzer
  attr_reader :logger

  def initialize(travis, repo_name, github_token)
    @github_token = github_token
    @repo_name = repo_name
    @travis = travis

    @logger = Logger.new(STDOUT)
    logger_datetime_format = "%Y-%m-%dT%H:%M:%S.%6N".freeze
    @logger.formatter = lambda do |severity, datetime, progname, msg|
      date_time = datetime.strftime(logger_datetime_format)
      prog_name = self.class.to_s.split("::").first
      "[#{date_time} ##{Process.pid}]  #{severity} -- #{prog_name}: #{msg}\n"
    end
  end
end
