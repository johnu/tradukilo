#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require

require 'minitest/autorun'
require 'irb'

class Parser
  OPERATORS = %w[<> <= >= = < >]

  def parse(text)

  end

  def translate_operator(operator)
    case operator
    when "="  then :eq
    when "<"  then :lt
    when ">"  then :gt
    when "<=" then :lte
    when ">=" then :gte
    when "<>" then :dne
    else
      raise "unexpected operator: #{operator}"
    end
  end
end

class ParserTest < MiniTest::Test
  def test_1_parse_single_value
    assert_equal Parser.new.parse("3"), { op: :eq, data: "3" }
  end

  def test_2_parse_single_lt
    assert_equal Parser.new.parse("< 4"), { op: :lt, data: "4" }
  end

  def test_3_parse_single_lte
    assert_equal Parser.new.parse("<= 4"), { op: :lte, data: "4" }
  end

  def test_4_parse_multiple_expressions
    assert_equal Parser.new.parse("> 5 || < 3"), { or: [{ op: :gt, data: "5"}, { op: :lt, data: "3"}] }
    assert_equal Parser.new.parse("5 || < 3"), { or: [{ op: :eq, data: "5"}, { op: :lt, data: "3"}] }
  end
end
