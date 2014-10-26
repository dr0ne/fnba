# parse_fnba.rb
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'pp'		


# Parse command line options
def parseOpts(args)

	# Default options
	options = {:verbose => false, :season => '2015'} 

	OptionParser.new do |opts|

		opts.banner = "Usage: predict.rb [options]"

		opts.separator ""
		opts.separator "Specific options:"

		opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
			options[:verbose] = v
		end

		# Get League 
		opts.on("-l", "--league LEAGUE_ID", "ESPN League ID") do |league|
			options[:league] = league
		end

		# Get Team ID
		opts.on("-t", "--team TEAM_ID,[TEAM2_ID, ...]", Array,"ESPN Team ID(s)") do |team|
			options[:team] = team
		end

		# Use defaults for testing
		opts.on("--test", "Use default test values (league = 23829, team = 12,14)") do |test|
			options[:test] = test
		end

		# Cache content, use cached version if available
		opts.on("-c","--cache", "Use cached content if available") do |format|
			options[:cache] = cache
		end

		# Display Help
		opts.on_tail('-h', '--help', 'Displays Help') do
			puts opts
		exit 0
		end

	end.parse!(args)
	return options

end # parseOpts()

# Parse FNBA team from ESPN URL
def parseTeam(url,verbose)

	# Open Team URL 
	# TODO: Add error handling
	page = Nokogiri::HTML(open(url))

	# Get team table
	table = page.css("table.playerTableTable");

	# Get players as rows
	rows = table.css("tr.pncPlayerRow")

	# Parse players from ESPN Player Table

	@players = rows.collect do |row|
		
		# Print HTML if verbose set for debugging
		if verbose
			pp row
		end

		player = {}
		[
			[:playerid, 'td[2]/a/@playerid'],
			[:slot, 'td[1]'],
			[:name, 'td[@class="playertablePlayerName"]/a'],
			[:fgPercent, 'td[@class="playertableStat "][2]'],
			[:ftPercent, 'td[@class="playertableStat "][4]'],
			[:threePointers, 'td[@class="playertableStat "][5]'],
			[:rebounds, 'td[@class="playertableStat "][6]'],
			[:assists, 'td[@class="playertableStat "][7]'],
			[:steals, 'td[@class="playertableStat "][8]'],
			[:blocks, 'td[@class="playertableStat "][9]'],
			[:turnovers, 'td[@class="playertableStat "][10]'],
			[:points, 'td[@class="playertableStat "][11]'],
			[:pr15, 'td[@class="playertableData"][1]'],
			[:ownPercent, 'td[@class="playertableData"][2]'],
			[:ownChange, 'td[@class="playertableData"][3]'],
		].each do |name, xpath|
			player[name] = row.xpath(xpath).text
		end
		
		# Special parsing for complex fields
		player[:team],*player[:position] = row.xpath('td[2]/text()').to_s.gsub('&nbsp;', ' ').delete(',').split(' ')
		# TODO: Improve opponent parsing to work for weekly and daily leagues
		player[:opponents] = row.xpath('td[4]/*/text()')

		player[:fgm],player[:fga] = row.xpath('td[@class="playertableStat "][1]').text.to_s.split('/')
		player[:ftm],player[:fta] = row.xpath('td[@class="playertableStat "][3]').text.to_s.split('/')	
		player
	end

	@players

end #parseTeam()

# Prints data for a given team
def printTeam(team)

	# Iterate through players
	team.each do |player|
		player.each {|key,value| puts "#{key},#{value}"}
	end

end #printTeam()


def compareTeams(teams)

# Fields
#playerid,1001
#slot,Bench
#name,Miles Plumlee
#fgPercent,.513
#ftPercent,.568
#threePointers,0.0
#rebounds,8.7
#assists,0.6
#steals,0.7
#blocks,1.2
#turnovers,1.5
#points,8.9
#pr15,--
#ownPercent,6.4
#ownChange,+2
#team,Pho
#position,["PF", "C"]
#opponents,LALSA@Uta
#fgm,3.9
#fga,7.7
#ftm,1.0
#fta,1.8

teams.each do |player|
	player.each {|key,value| puts "#{key},#{value}"}
end




end #compareTeams()


# Parse command line options if supplied, otherwise print help
if ARGV.count > 0
	options = parseOpts(ARGV)
else
	ARGV << "--help"
	parseOpts(ARGV)
	exit 0
end

# Process X number of teams

if !options[:league]
	puts "\nMust supply LEAGUE_ID!\n\n"
	exit 0
end

teams = Array.new

options[:team].each do |teamId|

	url = "http://games.espn.go.com/fba/playertable/prebuilt/manageroster?leagueId=#{options[:league]}&teamId=#{teamId}&seasonId=2015&scoringPeriodId=1&view=stats&context=clubhouse&version=projections&ajaxPath=playertable/prebuilt/manageroster&managingIr=false&droppingPlayers=false&asLM=false"
	teams << parseTeam(url,options[:verbose])
	
end

