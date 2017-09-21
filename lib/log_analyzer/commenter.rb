require "erb"
require "stringio"

module LogAnalyzer
  class Commenter

    RESULT_REPORTER_PATH = File.join(File.dirname(__FILE__), "comment.erb")
    RESULT_REPORTER_TEMPLATE = ERB.new(File.read(RESULT_REPORTER_PATH))

    attr_reader :build, :base_url

    def initialize(build)
      @build = build
      @base_url = "https://liaison-travislog2jira.herokuapp.com"
    end

    def generate
      RESULT_REPORTER_TEMPLATE.result(binding).gsub("\n", "")
    end
  end
end
