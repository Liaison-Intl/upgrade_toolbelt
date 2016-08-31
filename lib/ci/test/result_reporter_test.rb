require "minitest/autorun"
require_relative "../lib/rails_upgrade_analyzer"

class TestResult < MiniTest::Unit::TestCase

  def test_setting_attributes
    result1 = RailsUpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", tests: 3, passed: 2, failures: 5, errors: 7)
    result2 = RailsUpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", tests: 11, passed: 13, failures: 17, errors: 19)

    reporter = RailsUpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_equal "Branch | Tests | Passed | Failures | Errors | Passing %", line(reporter, 0)
    assert_equal ":----- | :---: | :----: | :------: | :----: | :-----:", line(reporter, 1)
    assert_equal "Result 1 | 3 | 2 | 5 | 7 | 66.67", line(reporter, 2)
    assert_equal "Result 2 | 11 | 13 | 17 | 19 | 118.18", line(reporter, 3)
  end

  def line(reporter, number)
    reporter.report.split("\n")[number]
  end
end
