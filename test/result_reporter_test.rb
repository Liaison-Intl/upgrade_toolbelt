require "test_helper"

class TestResult < MiniTest::Unit::TestCase

  def test_build_results
    result1 = RailsUpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", tests: 3, passed: 2, failures: 5, errors: 7)
    result2 = RailsUpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", tests: 11, passed: 13, failures: 17, errors: 19)

    reporter = RailsUpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_equal "<table>", line(reporter, 0)
    assert_equal "<thead>", line(reporter, 1)
    assert_equal "<th>Branch</th>", line(reporter, 2)
    assert_equal "<th>Tests</th>", line(reporter, 3)
    assert_equal "<th>Passed</th>", line(reporter, 4)
    assert_equal "<th>Failures</th>", line(reporter, 5)
    assert_equal "<th>Errors</th>", line(reporter, 6)
    assert_equal "<th>Passing %</th>", line(reporter, 7)
    assert_equal "</thead>", line(reporter, 8)
    assert_equal "<tbody>", line(reporter, 9)
    assert_equal "<tr>", line(reporter, 10)
    assert_equal "<td>Result 1</td>", line(reporter, 11)
    assert_equal "<td>3</td>", line(reporter, 12)
    assert_equal "<td>2</td>", line(reporter, 13)
    assert_equal "<td>5</td>", line(reporter, 14)
    assert_equal "<td>7</td>", line(reporter, 15)
    assert_equal "<td>66.67</td>", line(reporter, 16)
    assert_equal "</tr>", line(reporter, 17)

    assert_equal "<tr>", line(reporter, 18)
    assert_equal "<td>Result 2</td>", line(reporter, 19)
    assert_equal "<td>11</td>", line(reporter, 20)
    assert_equal "<td>13</td>", line(reporter, 21)
    assert_equal "<td>17</td>", line(reporter, 22)
    assert_equal "<td>19</td>", line(reporter, 23)
    assert_equal "<td>118.18</td>", line(reporter, 24)
    assert_equal "</tr>", line(reporter, 25)

    assert_equal "</tbody>", line(reporter, 26)
    assert_equal "</table>", line(reporter, 27)
    assert !reporter.deprecation_warnings_changed?
  end

  def test_nested_html_in_description
    result1 = RailsUpgradeAnalyzer::JobResult.new("1234.1", description: "<p>Inner HTML</p>", tests: 1)
    result2 = RailsUpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", tests: 2)

    reporter = RailsUpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_equal '<td><p>Inner HTML</p></td>', line(reporter, 11)
    assert !reporter.deprecation_warnings_changed?
  end

  def test_deprecation_warnings
    deprecations1 = { "A warning" => 1, "Another warning" => 9, "No diff" => 5 }
    deprecations2 = { "A warning" => 2, "No diff" => 5 }
    result1 = RailsUpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", deprecations: deprecations1)
    result2 = RailsUpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", deprecations: deprecations2)

    reporter = RailsUpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_equal "<table>", deprecation_line(reporter, 0)
    assert_equal "<thead>", deprecation_line(reporter, 1)
    assert_equal "<th>Deprecation</th>", deprecation_line(reporter, 2)
    assert_equal "<th>Result 1</th>", deprecation_line(reporter, 3)
    assert_equal "<th>Result 2</th>", deprecation_line(reporter, 4)
    assert_equal "<th>Difference</th>", deprecation_line(reporter, 5)
    assert_equal "</thead>", deprecation_line(reporter, 6)
    assert_equal "<tbody>", deprecation_line(reporter, 7)

    assert_equal "<tr>", deprecation_line(reporter, 8)
    assert_equal "<td>A warning</td>", deprecation_line(reporter, 9)
    assert_equal "<td>1</td>", deprecation_line(reporter, 10)
    assert_equal "<td>2</td>", deprecation_line(reporter, 11)
    assert_equal "<td>1</td>", deprecation_line(reporter, 12)
    assert_equal "</tr>", deprecation_line(reporter, 13)

    assert_equal "<tr>", deprecation_line(reporter, 14)
    assert_equal "<td>Another warning</td>", deprecation_line(reporter, 15)
    assert_equal "<td>9</td>", deprecation_line(reporter, 16)
    assert_equal "<td>0</td>", deprecation_line(reporter, 17)
    assert_equal "<td>-9</td>", deprecation_line(reporter, 18)
    assert_equal "</tr>", deprecation_line(reporter, 19)

    assert_equal "</tbody>", deprecation_line(reporter, 20)
    assert_equal "</table>", deprecation_line(reporter, 21)

    assert reporter.deprecation_warnings_changed?
  end

  def test_no_deprecation_difference
    deprecations1 = { "A warning" => 12 }
    deprecations2 = { "A warning" => 12 }
    result1 = RailsUpgradeAnalyzer::JobResult.new("1234.1", description: "Result 1", deprecations: deprecations1)
    result2 = RailsUpgradeAnalyzer::JobResult.new("1234.2", description: "Result 2", deprecations: deprecations2)

    reporter = RailsUpgradeAnalyzer::ResultReporter.new(result1, result2)

    assert_equal '<td colspan="4">12 deprecation(s) found on both builds.</td>', deprecation_line(reporter, 9)
    assert !reporter.deprecation_warnings_changed?
  end

  def line(reporter, number)
    reporter.report.split("\n")[number].to_s.strip
  end

  def deprecation_line(reporter, number)
    reporter.deprecation_report.split("\n")[number].to_s.strip
  end
end
