["bills", "federal_register"].each do |type|
  require File.join(File.dirname(__FILE__), type)
end