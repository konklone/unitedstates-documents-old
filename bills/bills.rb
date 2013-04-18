#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'

class Bills

  # elements to be turned into divs (must be listed explicitly)
  BLOCKS = %w{
    legis-body
    section subsection paragraph subparagraph subchapter 
    quoted-block
    toc toc-entry
  }

  # elements to be turned into spans (unlisted elements default to inline)
  INLINES = %w{
    after-quoted-block quote
    internal-xref external-xref
    text header enum
    short-title official-title
  }

  # Given a path to an XML file published by the House or Senate,
  # produce an HTML version of the document at the given output.
  def self.process(infile, outfile, options = {})
    doc = Nokogiri::XML open(infile)

    # let's start by just caring about the body of the bill - the legis-body
    body = doc.at "legis-body"
    body.traverse do |node|

      # for now, just strip out any attributes
      node.attributes.each do |key, value|
        node.attributes[key].remove
      end

      # turn into a div or span with a class of its old name
      name = node.name
      if BLOCKS.include?(name)
        node.name = "div"
      else # inline
        node.name = "span"
      end
      node["class"] = name
    end

    if outfile
      File.open(outfile, "w") {|f| f.write body.to_html}
    else
      puts body.to_html
    end
  end

end

if $0 == __FILE__
  options = {}
  
  infile = ARGV[0]

  (ARGV[1..-1] || []).each do |arg|
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

  outfile = options.delete :out

  Bills.process infile, outfile, options
end