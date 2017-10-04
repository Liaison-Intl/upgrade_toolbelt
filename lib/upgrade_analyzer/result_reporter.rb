require "erb"

module UpgradeAnalyzer
  class ResultReporter

    RESULT_REPORTER_PATH = File.join(File.dirname(__FILE__), "result_reporter.erb")
    RESULT_REPORTER_TEMPLATE = ERB.new(File.read(RESULT_REPORTER_PATH))

    def initialize(base_result, pull_request_result)
      @base_result = base_result
      @pull_request_result = pull_request_result
    end

    def deprecation_warnings_changed?
      @deprecation_warnings_changed ||= all_deprecation_categories.any? { |category| difference_for_category(category) != 0 }
    end

    def failed?
      pull_request_result.passing_percent < base_result.passing_percent
    end

    def report
      RESULT_REPORTER_TEMPLATE.result(binding).gsub("\n", "")
    end

    private

    attr_reader :base_result, :pull_request_result

    def all_deprecation_categories
      (base_deprecations.keys + pull_request_deprecations.keys).uniq.sort
    end

    def all_results
      @all_results = [base_result, pull_request_result]
    end

    def base_deprecations
      base_result.deprecations.default = 0
      base_result.deprecations
    end

    def difference_for_category(category)
      pull_request_deprecations[category] - base_deprecations[category]
    end

    def pull_request_deprecations
      pull_request_result.deprecations.default = 0
      pull_request_result.deprecations
    end

    def mark
      failed? ? ":x:" : ":white_check_mark:"
    end
  end
end
