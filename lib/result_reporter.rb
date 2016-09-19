require "stringio"
require "builder"

module UpgradeAnalyzer
  class ResultReporter

    def initialize(result1, result2)
      @result1 = result1
      @result2 = result2
    end

    def deprecation_report
      @deprecation_report ||= build_deprecation_report
    end

    def deprecation_warnings_changed?
      @deprecation_warnings_changed
    end

    def report
      @report ||= build_report
    end

    private

    attr_reader :result1, :result2

    def all_deprecation_categories
      (deprecations1.keys + deprecations2.keys).uniq.sort
    end

    def all_results
      @all_results = [result1, result2]
    end

    def build_deprecation_report
      builder = Builder::XmlMarkup.new(indent: 2)
      builder.table do |table|
        add_deprecation_report_header(table)

        table.tbody do |tbody|
          all_deprecation_categories.each do |category|
            difference = deprecations2[category] - deprecations1[category]
            if difference != 0
              tbody.tr do |tr|
                tr.td(category)
                tr.td(deprecations1[category])
                tr.td(deprecations2[category])
                tr.td(difference)
                @deprecation_warnings_changed = true
              end
            end
          end

          if !deprecation_warnings_changed?
            tbody.tr do |tr|
              tr.td("#{result1.deprecation_count} deprecation(s) found on both builds.", colspan: 4)
            end
          end
        end
      end
    end

    def build_report
      builder = Builder::XmlMarkup.new(indent: 2)
      builder.table do |table|
        add_report_header(table)

        table.tbody do |tbody|
          all_results.each do |result|
            tbody.tr do |tr|
              tr << "<td>#{result.description}</td>\n"
              tr.td(result.tests)
              tr.td(result.passed)
              tr.td(result.failures)
              tr.td(result.errors)
              tr.td(result.passing_percent)
            end
          end
        end
      end
    end

    def deprecations1
      result1.deprecations.default = 0
      result1.deprecations
    end

    def deprecations2
      result2.deprecations.default = 0
      result2.deprecations
    end

    def add_report_header(table)
      headers = ["Branch", "Tests", "Passed", "Failures", "Errors", "Passing %"]
      add_headers(table, headers)
    end

    def add_deprecation_report_header(table)
      headers = ["Deprecation", "Result 1", "Result 2", "Difference"]
      add_headers(table, headers)
    end

    def add_headers(table, headers)
      table.thead do |thead|
        headers.each do |column|
          thead.th(column)
        end
      end
    end
  end
end
