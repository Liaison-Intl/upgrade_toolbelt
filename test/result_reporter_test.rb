require "test_helper"
require "nokogiri"

class TestResult < MiniTest::Unit::TestCase
  def test_build_results
    result1 = UpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", tests: 3, passed: 2, failures: 5, errors: 7)
    result2 = UpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", tests: 11, passed: 13, failures: 17, errors: 19)

    reporter = UpgradeAnalyzer::ResultReporter.new(result1, result2)
    report = Nokogiri::HTML(reporter.report)

    assert_equal "Branch", report.css("th[1]").text
    assert_equal "Tests", report.css("th[2]").text
    assert_equal "Passed", report.css("th[3]").text
    assert_equal "Failures", report.css("th[4]").text
    assert_equal "Errors", report.css("th[5]").text
    assert_equal "Passing %", report.css("th[6]").text

    assert_equal "Result 1", report.css("tr[1] td[1]").text
    assert_equal "3", report.css("tr[1] td[2]").text
    assert_equal "2", report.css("tr[1] td[3]").text
    assert_equal "5", report.css("tr[1] td[4]").text
    assert_equal "7", report.css("tr[1] td[5]").text
    assert_equal "66.67", report.css("tr[1] td[6]").text

    assert_equal "Result 2", report.css("tr[2] td[1]").text
    assert_equal "11", report.css("tr[2] td[2]").text
    assert_equal "13", report.css("tr[2] td[3]").text
    assert_equal "17", report.css("tr[2] td[4]").text
    assert_equal "19", report.css("tr[2] td[5]").text
    assert_equal "118.18", report.css("tr[2] td[6]").text

    assert !reporter.deprecation_warnings_changed?
  end

  def test_nested_html_in_description
    result1 = UpgradeAnalyzer::JobResult.new("1234.1", description: "<p>Inner HTML</p>", tests: 1)
    result2 = UpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", tests: 2)

    reporter = UpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_includes reporter.report, "<p>Inner HTML</p>"
    assert !reporter.deprecation_warnings_changed?
  end

  def test_deprecation_warnings
    deprecations1 = { "A warning" => 1, "Another warning" => 9, "No diff" => 5 }
    deprecations2 = { "A warning" => 2, "No diff" => 5 }
    result1 = UpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", deprecations: deprecations1)
    result2 = UpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", deprecations: deprecations2)

    reporter = UpgradeAnalyzer::ResultReporter.new(result1, result2)
    report = Nokogiri::HTML(reporter.deprecation_report)

    assert_equal "Deprecation", report.css("th[1]").text
    assert_equal "Result 1", report.css("th[2]").text
    assert_equal "Result 2", report.css("th[3]").text
    assert_equal "Difference", report.css("th[4]").text

    assert_equal "A warning", report.css("tr[1] td[1]").text
    assert_equal "1", report.css("tr[1] td[2]").text
    assert_equal "2", report.css("tr[1] td[3]").text
    assert_equal "1", report.css("tr[1] td[4]").text

    assert_equal "Another warning", report.css("tr[2] td[1]").text
    assert_equal "9", report.css("tr[2] td[2]").text
    assert_equal "0", report.css("tr[2] td[3]").text
    assert_equal "-9", report.css("tr[2] td[4]").text

    assert reporter.deprecation_warnings_changed?
  end

  def test_no_deprecation_difference
    deprecations1 = { "A warning" => 12 }
    deprecations2 = { "A warning" => 12 }
    result1 = UpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", deprecations: deprecations1)
    result2 = UpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", deprecations: deprecations2)

    reporter = UpgradeAnalyzer::ResultReporter.new(result1, result2)
    report = Nokogiri::HTML(reporter.deprecation_report)

    assert_equal "12 deprecation(s) found on both builds.", report.css("td[colspan]").text
    assert !reporter.deprecation_warnings_changed?
  end
end
