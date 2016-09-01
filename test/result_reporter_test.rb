require "test_helper"

class TestResult < MiniTest::Unit::TestCase

  def test_build_results
    result1 = RailsUpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", tests: 3, passed: 2, failures: 5, errors: 7)
    result2 = RailsUpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", tests: 11, passed: 13, failures: 17, errors: 19)

    reporter = RailsUpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_equal "Branch | Tests | Passed | Failures | Errors | Passing %", line(reporter, 0)
    assert_equal ":----- | :---: | :----: | :------: | :----: | :-----:", line(reporter, 1)
    assert_equal "Result 1 | 3 | 2 | 5 | 7 | 66.67", line(reporter, 2)
    assert_equal "Result 2 | 11 | 13 | 17 | 19 | 118.18", line(reporter, 3)
    assert !reporter.deprecation_warnings_changed?
  end

  def test_deprecation_warnings
    deprecations1 = { "A warning" => 1, "Another warning" => 9, "No diff" => 5 }
    deprecations2 = { "A warning" => 2, "No diff" => 5 }
    result1 = RailsUpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", deprecations: deprecations1)
    result2 = RailsUpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", deprecations: deprecations2)

    reporter = RailsUpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_equal "Deprecation | Result 1 | Result 2 | Difference", deprecation_line(reporter, 0)
    assert_equal ":-- | :--: | :--: | :--:", deprecation_line(reporter, 1)
    assert_equal "A warning | 1 | 2 | 1", deprecation_line(reporter, 2)
    assert_equal "Another warning | 9 | 0 | -9", deprecation_line(reporter, 3)
    assert_equal nil, deprecation_line(reporter, 4)
    assert reporter.deprecation_warnings_changed?
  end

  def test_no_deprecations
    result1 = RailsUpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1")
    result2 = RailsUpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2")

    reporter = RailsUpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_equal "No deprecation differences found|", deprecation_line(reporter, 2)
    assert !reporter.deprecation_warnings_changed?
  end

  def line(reporter, number)
    reporter.report.split("\n")[number]
  end

  def deprecation_line(reporter, number)
    reporter.deprecation_report.split("\n")[number]
  end
end
