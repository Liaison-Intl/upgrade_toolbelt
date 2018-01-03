require "test_helper"
require_relative "../lib/deprecation_summary"

class DeprecationSummaryTest < Minitest::Test
  def test_no_deprecation
    content = ["None here"]
    summary = DeprecationSummary.new(content)

    assert_equal({}, summary.deprecations)
    assert_equal(0, summary.deprecation_count)
  end

  def test_with_deprecation
    warning = "DEPRECATION: Dependency 1 is too old"
    content = [warning]
    summary = DeprecationSummary.new(content)

    assert_equal({ warning => 1 }, summary.deprecations)
    assert_equal(1, summary.deprecation_count)
  end

  def test_with_multiple_deprecations
    warning1 = "DEPRECATION: Dependency 1 is too old"
    warning2 = "DEPRECATION: Dependency 2 is too old"
    line1 = "nothing to see here"

    content = [warning1, line1, warning2, warning1]
    summary = DeprecationSummary.new(content)

    assert_equal({ warning1 => 2, warning2 => 1 }, summary.deprecations)
    assert_equal(3, summary.deprecation_count)
  end

  def test_uses_only_first_sentence
    warning = "DEPRECATION: Dependency 1 is too old"
    full_line = "#{warning}. Bro dawgs are cool"
    content = [full_line]
    summary = DeprecationSummary.new(content)

    assert_equal({ warning => 1 }, summary.deprecations)
    assert_equal(1, summary.deprecation_count)
  end

  def test_ignores_content_before_deprecation
    warning = "DEPRECATION: Dependency 1 is too old."
    full_line = "bro dawgs #{warning}"
    content = [full_line]
    summary = DeprecationSummary.new(content)

    assert_equal({ warning => 1 }, summary.deprecations)
    assert_equal(1, summary.deprecation_count)
  end

  def test_it_normalizes_relation_option_deprecation
    warning = "DEPRECATION WARNING: The following options in your Applicant declaration are deprecated: some_option"
    normalized = "DEPRECATION WARNING: The following options in your [has_many or has_one] declaration are deprecated: some_option"
    content = [warning]
    summary = DeprecationSummary.new(content)

    assert_equal({ normalized => 1 }, summary.deprecations)
    assert_equal(1, summary.deprecation_count)
  end

  def test_it_normalizes_eager_load_deprecation
    warning = "DEPRECATION WARNING: It looks like you are eager loading table(s) (applicants) that are referenced in a string SQL snippet"
    normalized = "DEPRECATION WARNING: It looks like you are eager loading table(s) ([...]) that are referenced in a string SQL snippet"
    content = [warning]
    summary = DeprecationSummary.new(content)

    assert_equal({ normalized => 1 }, summary.deprecations)
    assert_equal(1, summary.deprecation_count)
  end
end
