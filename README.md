fnba
====

Fantasy NBA Tools

##Dependencies
`bundle install`

##Usage
```
Usage: fnba.rb [options]

Specific options:
    -v, --[no-]verbose               Run verbosely
    -l, --league LEAGUE_ID           ESPN League ID
    -t TEAM_ID,[TEAM2_ID, ...],      ESPN Team ID(s)
        --team
        --test                       Use default test values (league = 23829, team = 12,14)
    -c, --cache                      Use cached content if available
    -h, --help                       Displays Help
```

Example: `ruby fnba.rb -l 23829 -t 14,13`

