#!/usr/bin/ruby

# Outputs as CSV a list of parties with their vote and seat totals

require 'json'
require 'csv'
require 'cgi'

def all_posts
	jsons = Dir['data/*.json'].select { |fname| %r{/\d+\.json}.match(fname) }

	posts = []
	jsons.each do |fname|
		json = JSON.parse(IO.read(fname))['arrondissement']
		arrondissement = json['nom']
		json['postes'].each do |type, ps|
			ps = [ps] unless Array === ps
			ps.each do |p|
				p['type'] = type
				p['arrondissement'] = arrondissement
				posts << p
			end
		end
	end
	return posts
end

def councillors(posts)
	posts.select { |p| %w[maire ville].include?(p['type']) }
end

def by_party(posts)
	parties = {}
	posts.each do |p|
		p['candidats'].each do |c|
			party = CGI.unescapeHTML(c['parti'])
			votes = c['nb_voix_obtenues']
			win = (c['nb_voix_majorite'] > 0)
			
			pobj = (parties[party] ||= {seats: 0, votes: 0})
			pobj[:seats] += 1 if win
			pobj[:votes] += votes 
		end
	end
	return parties
end

def csv(io, stats)
	c = CSV.new(io)
	c << %w[Party Votes Seats]
	stats.sort_by { |name, p| p[:votes] }.reverse
		.each { |name, p| c << [name, p[:votes], p[:seats]] }
	c.close
end

stats = by_party(councillors(all_posts))
csv(STDOUT, stats)
