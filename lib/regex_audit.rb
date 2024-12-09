# frozen_string_literal: true

require_relative "regex_audit/version"

require "prism"
require "pp"

class RegexAudit
  class Error < StandardError; end

  attr_reader :path

  def initialize(path)
    @path = path
  end

  def unoptimized_regex
    return @unoptimized_regex if @unoptimized_regex
    @unoptimized_regex = []

    result = Prism.parse_file(path)
    result.value.accept(RegexAudit::Visitor.new(@unoptimized_regex))

    @unoptimized_regex
  end

  def print(io)
    unoptimized_regex.each do |node|
      io.puts "#{path}:#{node.location.start_line}"
      io.puts "  #{node.slice}"
    end
    #io.puts 
  end

  class Visitor < Prism::Visitor
    def initialize(regexps)
      @regexps = regexps
    end

    def visit_regular_expression_node(node)
      src = node.unescaped
      flags = 0
      flags |= Regexp::EXTENDED if node.extended?
      flags |= Regexp::IGNORECASE if node.ignore_case?
      flags |= Regexp::MULTILINE if node.multi_line?

      if node.ascii_8bit?
        src = src.b
      end

      #regex = Regexp.new(src, flags)
      unless Regexp.linear_time?(src, flags)
        @regexps << node
      end
      super
    end

    def visit_interpolated_regular_expression_node(node)
      # TODO: Not sure what to do. Warn? Check at runtime?
      super
    end
  end
end
