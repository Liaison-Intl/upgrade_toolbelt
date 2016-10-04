$LOAD_PATH.unshift(File.dirname(__FILE__))

require "optparse"
require "stringio"
require "octokit"
require "travis"

require "deprecation_summary"
require "github_proxy"
require "job_result"
require "result_reporter"
