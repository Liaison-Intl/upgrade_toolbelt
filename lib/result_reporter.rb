require "erb"
require "stringio"

module UpgradeAnalyzer
  class ResultReporter

    RESULT_REPORTER_PATH = File.join(File.dirname(__FILE__), "result_reporter.erb")
    RESULT_REPORTER_TEMPLATE = ERB.new(File.read(RESULT_REPORTER_PATH))

    def initialize(result1, result2)
      @result1 = result1
      @result2 = result2
    end

    def deprecation_warnings_changed?
      @deprecation_warnings_changed
    end

    def report
      RESULT_REPORTER_TEMPLATE.result(binding)
    end

    private

    attr_reader :result1, :result2

    def all_deprecation_categories
      (deprecations1.keys + deprecations2.keys).uniq.sort
    end

    def all_results
      @all_results = [result1, result2]
    end

    def deprecations1
      result1.deprecations.default = 0
      result1.deprecations
    end

    def deprecations2
      result2.deprecations.default = 0
      result2.deprecations
    end
  end
end
