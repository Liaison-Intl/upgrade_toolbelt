class DeprecationSummary

  def initialize(content)
    @content = content
  end

  def deprecations
    @deprecations ||= run
  end

  def deprecation_count
    deprecations.each_value.inject(&:+) || 0
  end

  private

  attr_reader :content

  def categorize(warning)
    if (match = warning.match(/^DEPRECATION WARNING: The following options in your .+? declaration are deprecated: (.+?)$/))
      options_used = match[1]
      category = "DEPRECATION WARNING: The following options in your [has_many or has_one] declaration are deprecated: #{options_used}"
    elsif warning.match(/^DEPRECATION WARNING: It looks like you are eager loading table\(s\) (\(.+?\)) that are referenced in a string SQL snippet/)
      category = 'DEPRECATION WARNING: It looks like you are eager loading table(s) ([...]) that are referenced in a string SQL snippet'
    else
      category = warning
    end
  end

  def run
    content.grep(/DEPRECATION/).inject(Hash.new(0)) do |warnings, line|
      clean = line.sub(/.*DEPRECATION/, 'DEPRECATION')
      warning = clean.split('. ').first.strip
      category = categorize(warning)
      warnings[category] += 1
      warnings
    end
  end
end
