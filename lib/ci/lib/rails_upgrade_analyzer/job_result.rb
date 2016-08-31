module RailsUpgradeAnalyzer
  class JobResult

    attr_reader :description, :job_number, :tests, :passed, :failures, :errors

    def initialize(job_number, options={})
      @job_number = job_number
      @description = options[:description]
      @tests = options.fetch(:tests, 0).to_i
      @passed = options.fetch(:passed, 0).to_i
      @failures = options.fetch(:failures, 0).to_i
      @errors = options.fetch(:errors, 0).to_i
    end

    def passing_percent
      return 0 if tests == 0

      ((passed.to_f / tests.to_f) * 100.0).round(2)
    end

    def <<(result)
      @tests += result.tests
      @passed += result.passed
      @failures += result.failures
      @errors += result.errors
    end
  end
end
