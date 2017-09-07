require "test_helper"
require "nokogiri"

module LogAnalyzer
  class CommenterTest < MiniTest::Unit::TestCase
    def test_comment
      build_mock = mock('build', pull_request_number: 42, number: 4242)
      commenter = Commenter.new(build_mock)
      comment = Nokogiri::HTML(commenter.generate)

      assert_equal "Build Log analysis: PR #42 has failures", comment.css("h1").text
      assert_equal "Please update JIRA for recurring failures.", comment.css("p").text
      assert_equal "https://liaison-travislog2jira.herokuapp.com/builds/4242", comment.css("p a").attr("href").value
    end
  end
end
