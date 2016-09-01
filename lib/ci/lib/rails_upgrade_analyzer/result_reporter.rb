require "stringio"

module RailsUpgradeAnalyzer
  class ResultReporter

    def initialize(result1, result2)
      @result1 = result1
      @result2 = result2
    end

    def deprecation_report
      @deprecation_report ||= build_deprecation_report
    end

    def deprecation_warnings_changed?
      @deprecation_warnings_changed
    end

    def report
      @report ||= build_report
    end

    private

    attr_reader :result1, :result2

    def all_deprecation_categories
      (deprecations1.keys + deprecations2.keys).uniq.sort
    end

    def all_results
      @all_results = [result1, result2]
    end

    def build_deprecation_report
      io = StringIO.new
      add_deprecation_report_header(io)

      all_deprecation_categories.each do |category|
        difference = deprecations2[category] - deprecations1[category]
        if difference != 0
          data = [category, deprecations1[category], deprecations2[category], difference]
          io << data.join(" | ")
          io << "\n"
          @deprecation_warnings_changed = true
        end
      end

      if !deprecation_warnings_changed?
        io << "No deprecation differences found|"
      end

      io.string
    end

    def build_report
      io = StringIO.new
      add_report_header(io)

      all_results.each do |result|
        data = [result.description, result.tests, result.passed, result.failures, result.errors, result.passing_percent]
        io << data.join(" | ")
        io << "\n"
      end

      io.string
    end

    def deprecations1
      result1.deprecations.default = 0
      result1.deprecations
    end

    def deprecations2
      result2.deprecations.default = 0
      result2.deprecations
    end

    def add_report_header(io)
      io << "Branch | Tests | Passed | Failures | Errors | Passing %\n"
      io << ":----- | :---: | :----: | :------: | :----: | :-----:\n"
    end

    def add_deprecation_report_header(io)
      io << "Deprecation | Result 1 | Result 2 | Difference\n"
      io << ":-- | :--: | :--: | :--:\n"
    end
  end
end
