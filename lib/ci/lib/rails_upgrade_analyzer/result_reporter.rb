require "stringio"

module RailsUpgradeAnalyzer
  class ResultReporter

    def initialize(*job_results)
      @job_results = job_results
    end

    def report
      @report ||= build_report
    end

    private

    attr_reader :job_results

    def build_report
      io = StringIO.new
      add_header(io)

      job_results.each do |result|
        data = [result.description, result.tests, result.passed, result.failures, result.errors, result.passing_percent]
        io << data.join(" | ")
        io << "\n"
      end

      io.string
    end

    def add_header(io)
      io << "Branch | Tests | Passed | Failures | Errors | Passing %\n"
      io << ":----- | :---: | :----: | :------: | :----: | :-----:\n"
    end
  end
end
