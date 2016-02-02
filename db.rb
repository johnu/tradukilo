#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require

require 'active_record'
require 'minitest/autorun'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table "scholarships" do |table|
    table.text     "name"
    table.datetime "start_at"
    table.float    "amount"
  end
end

Scholarship = Class.new(ActiveRecord::Base)

class ArelTest < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!

  def test_1_simple_equals
    table = Scholarship.arel_table
    transformer = ArelTransformer.new(table[:amount], 'integer')

    query = transformer.apply({ op: :eq, data: '3' }).to_sql

    assert_equal query, '"scholarships"."amount" = 3.0'
  end

  def test_2_simple_gt
    table = Scholarship.arel_table
    transformer = ArelTransformer.new(table[:amount], 'integer')

    query = transformer.apply({ op: :gt, data: '3' }).to_sql

    assert_equal query, '"scholarships"."amount" > 3.0'
  end

  def test_3_or_eq_gt
    table = Scholarship.arel_table
    transformer = ArelTransformer.new(table[:amount], 'integer')

    query = transformer.apply({ or: [{op: :eq, data: '3'}, {op: :gt, data: '10'}]}).to_sql

    assert_equal query, '("scholarships"."amount" = 3.0 OR "scholarships"."amount" > 10.0)'
  end

  def test_4_gt_date
    table = Scholarship.arel_table
    date = 1.day.ago.to_date.to_s
    transformer = ArelTransformer.new(table[:start_at], 'date')

    query = transformer.apply({op: :gt, data: date}).to_sql

    assert_equal query, "\"scholarships\".\"start_at\" > '#{date} 23:59:59.999999'"
  end

  def test_5_eq_date
    table = Scholarship.arel_table
    date = 1.day.ago.to_date.to_s
    transformer = ArelTransformer.new(table[:start_at], 'date')

    # If the query is an equals, we want any time in that date
    query = transformer.apply({op: :eq, data: date}).to_sql

    assert_equal query, "\"scholarships\".\"start_at\" >= '#{date} 00:00:00.000000' AND \"scholarships\".\"start_at\" <= '#{date} 23:59:59.999999'"
  end

end

class ArelTransformer
  attr_reader :field, :datatype

  def initialize(field, datatype)
    @field = field
    @datatype = datatype
  end

  def apply(value)
    if value[:or]
      value[:or].map{ |v| apply(v) }.inject(&:or)
    else
      data = transform_data(value[:data], value[:op])

      case value[:op]
      when :eq
        if datatype == 'date' && database_time?
          field.gteq(data.beginning_of_day).and(field.lteq(data.end_of_day))
        else
          field.eq(data)
        end
      when :gt
        field.gt(data)
      end
    end
  end

  def transform_data(value, op)
    if @datatype == "date" && database_time?
      time = Chronic.parse(value).getutc

      case op
      when :lt, :gte then time.beginning_of_day
      when :gt, :lte then time.end_of_day
      else
        time
      end
    else
      value
    end
  end

  def database_time?
    model = @field.relation.engine
    field_name = @field.name.to_s

    model.columns_hash[field_name].type == :datetime
  end
end
