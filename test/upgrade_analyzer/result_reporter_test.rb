require "test_helper"
require "nokogiri"

module UpgradeAnalyzer
  class ResultReporterTest < Minitest::Test
    def test_build_results
      result1 = JobResult.new("1234.1", description: "Result 1", tests: 3, passed: 2, failures: 5, errors: 7)
      result2 = JobResult.new("1234.2", description: "Result 2", tests: 11, passed: 13, failures: 17, errors: 19)

      reporter = ResultReporter.new(result1, result2)
      report = Nokogiri::HTML(reporter.report)

      report.css("#test_table").select do |table|
        assert_equal "Branch", table.css("th[1]").text
        assert_equal "Tests", table.css("th[2]").text
        assert_equal "Passed", table.css("th[3]").text
        assert_equal "Failures", table.css("th[4]").text
        assert_equal "Errors", table.css("th[5]").text
        assert_equal "Passing %", table.css("th[6]").text

        assert_equal "Result 1", table.css("tr[1] td[1]").text
        assert_equal "3", table.css("tr[1] td[2]").text
        assert_equal "2", table.css("tr[1] td[3]").text
        assert_equal "5", table.css("tr[1] td[4]").text
        assert_equal "7", table.css("tr[1] td[5]").text
        assert_equal "66.67", table.css("tr[1] td[6]").text

        assert_equal "Result 2", table.css("tr[2] td[1]").text
        assert_equal "11", table.css("tr[2] td[2]").text
        assert_equal "13", table.css("tr[2] td[3]").text
        assert_equal "17", table.css("tr[2] td[4]").text
        assert_equal "19", table.css("tr[2] td[5]").text
        assert_equal "118.18", table.css("tr[2] td[6]").text
      end

      assert !reporter.deprecation_warnings_changed?
    end

    def test_pass_fail
      result1 = JobResult.new("1234.1", description: "Result 1", tests: 10, passed: 8, failures: 1, errors: 1)
      result2 = JobResult.new("1234.2", description: "Result 2", tests: 10, passed: 9, failures: 1, errors: 0)

      reporter = ResultReporter.new(result1, result2)

      assert !reporter.failed?

      result2.passed = 7
      result2.errors = 2

      assert reporter.failed?
    end

    def test_nested_html_in_description
      result1 = JobResult.new("1234.1", description: "<p>Inner HTML</p>", tests: 1)
      result2 = JobResult.new("1234.2", description: "Result 2", tests: 2)

      reporter = ResultReporter.new(result1, result2)

      assert_includes reporter.report, "<p>Inner HTML</p>"
      assert !reporter.deprecation_warnings_changed?
    end

    def test_deprecation_warnings
      deprecations1 = { "A warning" => 1, "Another warning" => 9, "No diff" => 5 }
      deprecations2 = { "A warning" => 2, "No diff" => 5 }
      result1 = JobResult.new("1234.1", description: "Result 1", deprecations: deprecations1)
      result2 = JobResult.new("1234.2", description: "Result 2", deprecations: deprecations2)

      reporter = ResultReporter.new(result1, result2)
      report = Nokogiri::HTML(reporter.report)

      report.css("#deprecation_table").select do |table|
        assert_equal "Deprecation", table.css("th[1]").text
        assert_equal "Result 1", table.css("th[2]").text
        assert_equal "Result 2", table.css("th[3]").text
        assert_equal "Difference", table.css("th[4]").text

        assert_equal "A warning", table.css("tr[1] td[1]").text
        assert_equal "1", table.css("tr[1] td[2]").text
        assert_equal "2", table.css("tr[1] td[3]").text
        assert_equal "1", table.css("tr[1] td[4]").text

        assert_equal "Another warning", table.css("tr[2] td[1]").text
        assert_equal "9", table.css("tr[2] td[2]").text
        assert_equal "0", table.css("tr[2] td[3]").text
        assert_equal "-9", table.css("tr[2] td[4]").text
      end

      assert reporter.deprecation_warnings_changed?
    end

    def test_no_deprecation_difference
      deprecations1 = { "A warning" => 12 }
      deprecations2 = { "A warning" => 12 }
      result1 = JobResult.new("1234.1", description: "Result 1", deprecations: deprecations1)
      result2 = JobResult.new("1234.2", description: "Result 2", deprecations: deprecations2)

      reporter = ResultReporter.new(result1, result2)
      report = Nokogiri::HTML(reporter.report)

      assert_includes report.css("td[colspan]").text, "12 deprecation(s) found on both builds."
      assert !reporter.deprecation_warnings_changed?
    end
  end
end
