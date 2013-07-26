#!/usr/bin/env ruby2
require 'csv'
require 'set'

# Abstract out the special bits needed for Ville de Montreal data tables
class Table
	include Enumerable
	
	# int_fields is a proc that takes a field name, and returns true if it
	# should be converted to an integer
	def initialize(path, int_fields = nil)
		@int_fields = int_fields || proc { |f| false }
		@csv = CSV.open(path, :col_sep => ';', :headers => :first_row,
			:encoding => 'ISO-8859-1:UTF-8')
		@csv.convert { |v,f| @int_fields[f.header] ? v.to_i : v }
	end
	
	def each(&block); @csv.each(&block); end
end

# Which elected positions correspond to city councillors?
positions = Table.new('ElectionGene-2009_PostesElectifs.csv')
councillor_types = Set["Conseiller de ville", "Maire d'arrondissement"]
councillor_positions = Set[]
positions.each do |r|
	councillor_positions << r['no'] if councillor_types.include?(r['type'])
end

# Total up votes per party for those positions
votes = Table.new('ElectionGene-2009_DistributionDesVotes.txt',
	proc { |f| /votes/i.match(f) })
totals = Hash.new(0)
votes.each do |r|
	next unless councillor_positions.include?(r['Poste'])
	totals[r['Parti']] += r['Votes']
end

# Print out the totals
totals.sort_by { |p, v| v }.reverse.each do |p, v|
	puts "%7d  %s" % [v, p]
end
