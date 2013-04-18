#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'

class Bills

  # Given a path to an XML file published by the House or Senate,
  # produce an HTML version of the document at the given output.
  def self.process(infile, outfile, options = {})
    puts infile, outfile, options
    # doc = Nokogiri::XML open(infile)


  end

end

if $0 == __FILE__
  options = {}
  (ARGV || []).each do |arg|
    if arg.start_with?("--")
      if arg["="]
        key, value = arg.split('=')
      else
        key, value = [arg, true]
      end
      
      key = key.split("--")[1]
      if value == 'true'
        value = true
      elsif value == 'False'
        value = false
      end
      options[key.downcase.to_sym] = value
    end
  end
  
  infile = options.delete :in
  outfile = options.delete :out

  Bills.process infile, outfile, options
end