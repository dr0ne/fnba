# predict.rb
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'pp' #pretty printer for testing
require 'optparse'
require 'ostruct'
#function parse lineup

test_file = "projections_dan.html"

#remote testing
#page = Nokogiri::HTML(open("http://games.espn.go.com/fba/clubhouse?leagueId=23829&teamId=14&seasonId=2015"))

#url "http://games.espn.go.com/fba/playertable/prebuilt/manageroster?leagueId=23829&teamId=14&seasonId=2015&scoringPeriodId=1&view=stats&context=clubhouse&version=lastSeason&ajaxPath=playertable/prebuilt/manageroster&managingIr=false&droppingPlayers=false&asLM=false&r=39476976"

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
		opts.on('-h', '--help', 'Displays Help') do
			puts opts
		exit
		end

	end.parse!(args)
	return options

end # parseOpts()

# Parse team details given a URL

def parseTeam(url)

	#local testing
	#page = Nokogiri::HTML(open("projections_dan.html"))

	#remote testing
	page = Nokogiri::HTML(open(url))

	# Get team table
	table = page.css("table.playerTableTable");

	# Get players as rows
	rows = table.css("tr.pncPlayerRow")

	@players = parsePlayers(rows)

	# test parsing by outputting teams player names
	@players.each do |player|
		puts player[:name]
	end

end # parseTeam()



def parsePlayers(rows)

	# Player Row Format
	#
	#<td id="slot_646" class="slot_0 playerSlot" style="font-weight: bold;">PG</td>
	#<td class="playertablePlayerName" id="playername_646" style="">
	#<a href="" class="flexpop" content="tabs#ppc" instance="_ppc" fpopheight="357px" fpopwidth="490px" tab="null" leagueid="23829" playerid="646" teamid="-2147483648" seasonid="2015" cache="true">Jeff Teague</a>, Atl PG</td>
	#<td class="sectionLeadingSpacer"></td>
	#<td class="cumulativeOpponents">2: <a href="http://sports.espn.go.com/nba/clubhouse?team=tor" target="_blank">@Tor</a>, <a href="http://sports.espn.go.com/nba/clubhouse?team=ind" target="_blank">Ind</a>
	#</td>
	#<td class="sectionLeadingSpacer"></td>
	#<td class="playertableStat ">5.8/13.2</td>
	#<td class="playertableStat ">.438</td>
	#<td class="playertableStat ">4.0/4.8</td>
	#<td class="playertableStat ">.846</td>
	#<td class="playertableStat ">0.9</td>
	#<td class="playertableStat ">2.6</td>
	#<td class="playertableStat ">6.7</td>
	#<td class="playertableStat ">1.1</td>
	#<td class="playertableStat ">0.2</td>
	#<td class="playertableStat ">2.9</td>
	#<td class="playertableStat ">16.5</td>
	#<td class="sectionLeadingSpacer"></td>
	#<td class="playertableData">--</td>
	#<td class="playertableData"><nobr>100.0</nobr></td>
	#<td class="playertableData"><nobr>+0</nobr></td>


	@players = rows.collect do |row|
		player = {}
		[
			[:slot, 'td[1]/text()'],
			[:name, 'td[2]/a/text()'],
			[:teamPosition, 'td[2]/text()'],
			[:opponents, 'td[4]/a/text()'],
			[:fgmfga, 'td[6]/text()'],
			[:fgPercent, 'td[7]/text()'],
			[:ftmfta, 'td[8]/text()'],
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
			player[name] = row.at_xpath(xpath.to_s.strip)
			#debug parsing
				#puts name.to_s.chomp + " " + player[name]
		end
		player
	end

	return @players

end #parsePlayers()

options = parseOpts(ARGV)

if options[:league] && options[:team]
	url = "http://games.espn.go.com/fba/playertable/prebuilt/manageroster?leagueId=#{options[:league]}&teamId=#{options[:team]}&seasonId=2015&scoringPeriodId=1&view=stats&context=clubhouse&version=lastSeason&ajaxPath=playertable/prebuilt/manageroster&managingIr=false&droppingPlayers=false&asLM=false"
elsif options[:test]
	url = "#{test_file}"
else
	url = "http://games.espn.go.com/fba/playertable/prebuilt/manageroster?leagueId=23829&teamId=14&seasonId=2015&scoringPeriodId=1&view=stats&context=clubhouse&version=lastSeason&ajaxPath=playertable/prebuilt/manageroster&managingIr=false&droppingPlayers=false&asLM=false"
end

puts "URL: #{url}\n"
parseTeam(url)

#pp options[:league]
#pp options[:team]

#pp options
#pp ARGV




