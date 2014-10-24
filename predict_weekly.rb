# predict_weekly.rb
require 'rubygems'
require 'nokogiri'
require 'open-uri'


#function parse lineup

page = Nokogiri::HTML(open("http://games.espn.go.com/fba/clubhouse?leagueId=23829&teamId=14&seasonId=2015"))

puts page.css("table.playerTableTable");

#function suggest team


