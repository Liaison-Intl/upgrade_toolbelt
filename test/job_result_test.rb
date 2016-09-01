require "test_helper"

class TestResult < MiniTest::Unit::TestCase

  def test_setting_attributes
    result = RailsUpgradeAnalyzer::JobResult.new("jobnum", description: "description", tests: 1, passed: 2, failures: 3, errors: 4)

    assert_equal "jobnum", result.job_number
    assert_equal "description", result.description
    assert_equal 1, result.tests
    assert_equal 2, result.passed
    assert_equal 3, result.failures
    assert_equal 4, result.errors
  end

  def test_setting_attributes_with_string
    result = RailsUpgradeAnalyzer::JobResult.new("jobnum", tests: "1", passed: "2", failures: "3", errors: "4")

    assert_equal 1, result.tests
    assert_equal 2, result.passed
    assert_equal 3, result.failures
    assert_equal 4, result.errors
  end

  def test_default_attributes
    result = RailsUpgradeAnalyzer::JobResult.new("jobnum")

    assert_equal "jobnum", result.job_number
    assert_equal 0, result.tests
    assert_equal 0, result.passed
    assert_equal 0, result.failures
    assert_equal 0, result.errors
  end

  def test_passing_percent
    result = RailsUpgradeAnalyzer::JobResult.new("jobnum", tests: 3, passed: 1)

    assert_equal 33.33, result.passing_percent
  end

  def test_divide_by_zero
    result = RailsUpgradeAnalyzer::JobResult.new("jobnum", tests: 0, passed: 1)

    assert_equal 0, result.passing_percent
  end

  def test_adding_results
    deprecations1 = { "warning1" => 1 }
    deprecations2 = { "warning1" => 2, "warning2" => 9 }
    result1 = RailsUpgradeAnalyzer::JobResult.new("jobnum", tests: 2, passed: 3, failures: 5, errors: 7, deprecations: deprecations1)
    result2 = RailsUpgradeAnalyzer::JobResult.new("jobnum", tests: 11, passed: 13, failures: 17, errors: 19, deprecations: deprecations2)

    result1 << result2

    assert_equal 13, result1.tests
    assert_equal 16, result1.passed
    assert_equal 22, result1.failures
    assert_equal 26, result1.errors
    assert_equal({ "warning1" => 3, "warning2" => 9 }, result1.deprecations)
  end

  def test_with_deprecations
    result = RailsUpgradeAnalyzer::JobResult.new("jobnum", deprecations: { "warning1" => 99 })

    assert_equal({ "warning1" => 99 }, result.deprecations)
  end

  def test_without_deprecations
    result = RailsUpgradeAnalyzer::JobResult.new("jobnum")

    assert_equal(Hash.new, result.deprecations)
  end
end
