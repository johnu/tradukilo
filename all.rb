#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require

load 'parser.rb'
load 'db.rb'

Scholarship.create(name: 'JohnU',  start_at: 1.week.from_now, amount: 5_000)
Scholarship.create(name: 'JanisU', start_at: 1.year.from_now, amount: 10_000)


puts "-------------------------------------------"

arel_table = Scholarship.arel_table

transformer = ArelTransformer.new(arel_table[:start_at], "date")
date = 6.months.from_now.to_s
parsed_term = Parser.new.parse("> #{date}")
date_query = transformer.apply(parsed_term)

transformer = ArelTransformer.new(arel_table[:amount], "int")
parsed_term = Parser.new.parse("> 7500")
amount_query = transformer.apply(parsed_term)

query = date_query.and(amount_query)

puts Scholarship.where(query).to_sql

Scholarship.where(query).each do |s|
  puts s.inspect
end

puts "-------------------------------------------"
