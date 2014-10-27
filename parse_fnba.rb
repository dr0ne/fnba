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


#
# calcTotals(teams) - Tally up matchup totals for each team
#
def calcTotals(teams)

teamTotals = Array.new

# TODO: Remove this flag for daily league hack
daily = 0

@teamTotals = teams.collect do |team|
	# Initialise totals hash
	totals = {}
	[
		[:fgPercent, 0.0],
		[:ftPercent, 0.0],
		[:threePointers, 0.0],
		[:rebounds, 0.0],
		[:assists, 0.0],
		[:steals, 0.0],
		[:blocks, 0.0],
		[:turnovers, 0.0],
		[:points, 0.0],
		[:fgm, 0.0],
		[:fga, 0.0],
		[:ftm, 0.0],
		[:fta, 0.0],
	].each do |key,value|
		totals[key] = value
	end

	team.each do |player|
		# Ignore benched players
		if player[:slot] != "Bench" || daily
			# Multiply by number of games player has
			games = player[:opponents].count

			# TODO: Remove this hack for daily leagues, assume everyone has 1 game
			if games == 0
				games = 1
				daily = 1
			end

			# Sum counting stats
			totals[:threePointers] += player[:threePointers].to_f * games
			totals[:rebounds] += player[:rebounds].to_f * games
			totals[:assists] += player[:assists].to_f * games
			totals[:steals] += player[:steals].to_f * games
			totals[:blocks] += player[:blocks].to_f * games
			totals[:turnovers] += player[:turnovers].to_f * games
			totals[:points] += player[:points].to_f * games
			totals[:fgm] += player[:fgm].to_f * games
			totals[:fga] += player[:fga].to_f * games
			totals[:ftm] += player[:ftm].to_f * games
			totals[:fta] += player[:fta].to_f * games
		end
	end
#Calculate Averages
totals[:fgPercent] = totals[:fgm] / totals[:fga]
totals[:ftPercent] = totals[:ftm] / totals[:fta]

totals
end

@teamTotals

end #calcTotals()

#
#	compareTeams(teamTotals) - Compare teams for a given matchup
#

def compareTeams(teamTotals)

	#TODO: Store team name and details for printing - also allow custom categories
	team1 = 0
	team2 = 0
	header = "Stat"

	

	printf("%-20s",header)
	puts "Team 1\tTeam 2\n"
	
	teamTotals[0].each do |stat,value|
		
		# TODO: fix this - Skip unused categories for now
		if stat.to_s != 'fgm' && stat.to_s != 'fga' && stat.to_s != 'ftm' && stat.to_s != 'fta'
		
			# Print row name
			printf("%-20s",stat)
	
			if teamTotals[0][stat] > teamTotals[1][stat] || (stat.to_s == 'turnovers' && teamTotals[0][stat] < teamTotals[1][stat])
				#Team 1 wins
				puts green(teamTotals[0][stat].round(3)) + "\t" + red(teamTotals[1][stat].round(3)) + "\n"
				team1 += 1
			else
				#Team 2 wins
				puts red(teamTotals[0][stat].round(3)) + "\t" + green(teamTotals[1][stat].round(3)) + "\n"
				team2 += 1
			end
		end
	end

	if(team1 > team2)
		puts green("\nTeam 1 wins with #{team1} of #{team1 + team2} categories\n") 
	elsif(team2 > team1)
		puts green("\nTeam 2 wins with #{team2} of #{team1 + team2} categories\n") 
	else
		puts green("\nDraw!\n")
	end

end #compareTeams()

#
# Methods to colorize text at the command line
#

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end


#
#	Begin Main
#

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

teamTotals = calcTotals(teams)

compareTeams(teamTotals)

