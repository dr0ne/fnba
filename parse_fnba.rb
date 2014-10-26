# parse_fnba.rb
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'pp'		#pp for debugging

# Local test file
test_file = "projections_dan.html"

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
		opts.on("-t", "--team TEAM_ID", "ESPN Team ID") do |team|
			options[:team] = team
		end

		# Enable Test Mode
		opts.on("--test", "Test Mode") do |test|
			options[:test] = test
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
		player[:fgtest] = row.xpath('td[@class="playertableData"][3]').text		
		player
	end

	@players

end #parseTeam()



# Parse command line options if supplied, otherwise print help
if ARGV.count > 0
	options = parseOpts(ARGV)
else
	ARGV << "--help"
	parseOpts(ARGV)
	exit 0
end

# If a league and team is supplied, use a specific URL, if test supplied, use local test URL
if options[:league] && options[:team]
	url = "http://games.espn.go.com/fba/playertable/prebuilt/manageroster?leagueId=#{options[:league]}&teamId=#{options[:team]}&seasonId=2015&scoringPeriodId=1&view=stats&context=clubhouse&version=projections&ajaxPath=playertable/prebuilt/manageroster&managingIr=false&droppingPlayers=false&asLM=false"
elsif options[:test]
	url = "#{test_file}"
else
	puts "Something went wrong!\n"
	exit 0
end

puts "Parsing data for URL: #{url}\n"

@team1 = parseTeam(url,options[:verbose])

#Print Team1
@team1[1].each do |player|
	puts player
end



