#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require

require 'active_support/all'
require 'minitest/autorun'

class ArelTest < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!

  def test_1_simple_equals
    transformer = SqlTransformer.new("scholarships.amount", 'integer', 'int')

    query = transformer.apply({ op: :eq, data: '3' })

    assert_equal query, 'scholarships.amount = 3'
  end

  def test_2_simple_gt
    transformer = SqlTransformer.new("scholarships.amount", 'integer', 'int')

    query = transformer.apply({ op: :gt, data: '3' })

    assert_equal query, 'scholarships.amount > 3'
  end

  def test_3_or_eq_lt
    transformer = SqlTransformer.new("scholarships.amount", 'integer', 'int')

    query = transformer.apply({ or: [{op: :eq, data: '3'}, {op: :gt, data: '10'}]})

    assert_equal query, '(scholarships.amount = 3 OR scholarships.amount > 10)'
  end

  def test_4_lt_date
    date = 1.day.ago.to_date.to_s
    transformer = SqlTransformer.new("scholarships.start_at", 'date', 'datetime')

    query = transformer.apply({op: :gt, data: date})

    assert_equal query, "scholarships.start_at > '#{date} 23:59:59'"
  end

  def test_5_gt_date
    date = 1.day.ago.to_date.to_s
    transformer = SqlTransformer.new("scholarships.start_at", 'date', 'datetime')

    query = transformer.apply({op: :gt, data: date})

    assert_equal query, "scholarships.start_at > '#{date} 23:59:59'"
  end

end

class SqlTransformer
  attr_reader :field, :datatype, :db_type

  def initialize(field, datatype, db_type)
    @field = field
    @datatype = datatype
    @db_type = db_type
  end

  def apply(value)

  end

  def transform_data(value, op)
    if @datatype == "date" && database_time?
      date = Chronic.parse(value).getutc

      time = case op
             when :lt, :gte then date.beginning_of_day
             when :gt, :lte then date.end_of_day
             else
               date
             end

      "'#{time.to_s(:db)}'"
    else
      value
    end
  end

  def database_time?
    db_type == 'datetime'
  end
end
