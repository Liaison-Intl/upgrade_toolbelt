module UpgradeAnalyzer
  class JobResult

    attr_reader :deprecations, :description, :job_number, :tests, :passed, :failures, :errors

    def initialize(job_number, options={})
      @job_number = job_number
      @description = options[:description]
      @tests = options.fetch(:tests, 0).to_i
      @passed = options.fetch(:passed, 0).to_i
      @failures = options.fetch(:failures, 0).to_i
      @errors = options.fetch(:errors, 0).to_i
      @deprecations = options.fetch(:deprecations, Hash.new(0))
    end

    def deprecation_count
      deprecations.values.inject(&:+) || 0
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

      deprecations.default = 0
      result.deprecations.default = 0

      (deprecations.keys + result.deprecations.keys).uniq.each do |category|
        deprecations[category] += result.deprecations[category]
      end
    end
  end
end
