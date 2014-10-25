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
def parseTeam(url)

	# Open Team URL 
	# TODO: Add error handling
	page = Nokogiri::HTML(open(url))

	# Get team table
	table = page.css("table.playerTableTable");

	# Get players as rows
	rows = table.css("tr.pncPlayerRow")

	# Parse players from ESPN Player Table

	@players = rows.collect do |row|
		player = {}
		[
			[:playerid, 'td[2]/a/@playerid'],
			[:slot, 'td[1]/text()'],
			[:name, 'td[2]/a/text()'],
			[:fgPercent, 'td[7]/text()'],
			[:ftPercent, 'td[9]/text()'],
			[:threePointers, 'td[10]/text()'],
			[:rebounds, 'td[11]/text()'],
			[:assists, 'td[12]/text()'],
			[:steals, 'td[13]/text()'],
			[:blocks, 'td[14]/text()'],
			[:turnovers, 'td[15]/text()'],
			[:points, 'td[16]/text()'],
			[:pr15, 'td[18]/text()'],
			[:ownPercent, 'td[19]/nobr/text()'],
			[:ownChange, 'td[20]/nobr/text()|td[20]/nobr/span/text()'],
		].each do |name, xpath|
			player[name] = row.at_xpath(xpath)
		end
		
		# Special parsing for complex fields
		player[:team],*player[:position] = row.xpath('td[2]/text()').to_s.gsub('&nbsp;', ' ').delete(',').split(' ')
		player[:opponents] = row.xpath('td[4]/*/text()')
		player[:fgm],player[:fga] = row.xpath('td[6]/text()').to_s.split('/')
		player[:ftm],player[:fta] = row.xpath('td[8]/text()').to_s.split('/')
		
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
	url = "http://games.espn.go.com/fba/playertable/prebuilt/manageroster?leagueId=#{options[:league]}&teamId=#{options[:team]}&seasonId=2015&scoringPeriodId=1&view=stats&context=clubhouse&version=lastSeason&ajaxPath=playertable/prebuilt/manageroster&managingIr=false&droppingPlayers=false&asLM=false"
elsif options[:test]
	url = "#{test_file}"
else
	puts "Something went wrong!\n"
	exit 0
end

puts "Parsing data for URL: #{url}\n"

@team1 = parseTeam(url)

#Print Team1
@team1[1].each do |player|
	puts player
end



