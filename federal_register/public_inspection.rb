#!/usr/bin/env ruby


def get_plain_text(pdf_path)
  raw_text = `pdftotext -enc UTF-8 #{pdf_path} -`
  # raw_text.gsub!(/-{3,}/, '') # remove '----' etc
  # raw_text.gsub!(/\.{4,}/, '') # remove '....' etc
  # raw_text.gsub!(/_{2,}/, '') # remove '____' etc
  # raw_text.gsub!(/\\\d+\\/, '') # remove '\16\' etc
  # raw_text.gsub!(/\|/, '') # remove '|'
  # raw_text.gsub!(/\n\d+\n\n/,"\n") # remove page numbers
  raw_text
end

def get_layout_text(pdf_path)
  raw_text = `pdftotext -layout -enc UTF-8 #{pdf_path} -`

  # add extra space to some things so that when space is collapsed,
  # they are still separate
  raw_text.gsub!(/(List of Subjects.*?\n\n {4,6})/im) do |list|
    "\n\n#{list}"
  end

  # paragraph breaks
  raw_text.gsub! /\.\n\n {4,6}/, ".\n\n\n\n"

  # too-big spaces after sentences
  raw_text.gsub!(/\. {2,}([A-Za-z])/) {". #{$1}"}

  # remove page breaks (and page numbers)
  raw_text.gsub! /\n\n +\d+\n\f/, "\n"

  #### collapse line breaks ### (affects regexes after)
  raw_text.gsub! "\n\n", "\n"

  # headers
  raw_text.gsub!(/(?:(\.)\n)?( *)([0-9a-zA-Z]+\.) +([^\n]+)\n {4,6}/) do |match|
    needs_line_above = ($1 && $1.size > 0)
    leading_space = ($2 && $2.size > 0)
    "#{needs_line_above ? ".\n\n" : ""}#{leading_space ? "\n" : ""}#{$3} #{$4}\n\n"
  end

  # add a line before major headers
  raw_text.gsub!(/^([ A-Z]{3,}\: +)/) { "\n#{$1.strip} "}

  # subparagraphs
  raw_text.gsub!(/\n *\([a-zA-Z0-9]+\) +/) {|match| "\n#{match}"}

  # ditch header
  raw_text.sub! /^.*?_{8,}/m, ''

  # ditch footer
  raw_text.sub! /\[FR Doc\.[^\n]+Filed[^\]]+\]/im, ''

  raw_text.strip
end

pdf_path = ARGV[0]

text = get_layout_text pdf_path
File.open("out-layout.txt", "w") {|f| f.write text}