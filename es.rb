#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require

require 'active_support/all'
require 'minitest/autorun'

class EsTest < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!

  def test_1_simple_equals
    transformer = EsTransformer.new('amount', 'integer')

    query = transformer.apply({op: :eq, data: '3'})

    assert_equal(query,
                 { term: {"amount" => "3"} })
  end

  def test_2_simple_gt
    transformer = EsTransformer.new('amount', 'integer')

    query = transformer.apply({op: :lt, data: '3'})

    assert_equal(query,
                 { range: { "amount" => { lt: "3" } } })
  end

  def test_4_or_eq_lt
    transformer = EsTransformer.new('amount', 'integer')

    query = transformer.apply({ or: [ { op: :eq, data: '3' }, { op: :lt, data: '10' }]})

    assert_equal(query,
                 { or: [{ term: { "amount" => "3"} }, { range: { "amount" => { lt: "10"} } }] })
  end

  def test_5_lt_date
    date = 1.day.ago.to_date.to_s
    transformer = EsTransformer.new('start_at', 'date')

    query = transformer.apply({op: :lt, data: date})

    assert_equal(query,
                 { range: { "start_at" => { lt: Chronic.parse("#{date} 06:00:00 UTC") } } })

  end

end

class EsTransformer
  attr_reader :field, :datatype

  def initialize(field, datatype)
    @field = field
    @datatype = datatype
  end

  def apply(value)

  end

  def transform_data(value, op)
    if datatype == "date"
      time = Chronic.parse(value)

      case op
      when :lt, :gte then time.beginning_of_day.getutc
      when :gt, :lte then time.end_of_day.getutc
      else
        time
      end
    else
      value
    end
  end
end
