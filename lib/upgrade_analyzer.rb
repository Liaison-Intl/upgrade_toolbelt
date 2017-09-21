$LOAD_PATH.unshift(File.dirname(__FILE__))

require "optparse"
require "stringio"

require "deprecation_summary"
require "github_proxy"
require "upgrade_analyzer/job_result"
require "upgrade_analyzer/result_reporter"
require "upgrade_analyzer/analyzer"
