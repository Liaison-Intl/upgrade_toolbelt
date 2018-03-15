# There is a bug in the Travis gem (at least as recent as 1.8.8) that causes it to fail loading the log. The below overrides solve the problem.
#
# Ref: https://github.com/travis-ci/travis.rb/issues/578#issuecomment-368142083

class Hash
  def to_struct
    Struct.new(*keys).new(*values)
  end
end

module Travis
  module Client
    class Session

      def load(data)
        result = {}
        if data.is_a?(String)
          return { log: { attributes: { body: data }}.to_struct}.to_struct
        end
        (data || {}).each_pair do |key, value|
          entity = load_entity(key, value)
          result[key] = entity if entity
        end
        result
      rescue => e
        puts e.message
        puts e.backtrace.join("\n")
      end
    end
  end
end
# End Travis Overrides
