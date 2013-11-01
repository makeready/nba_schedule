require 'nokogiri'
require 'open-uri'

class Nbareader
  def initialize
    @nba_url = "http://api.sportsdatallc.org/nba-t3/games/2013/reg/schedule.xml?api_key=ukesef6h6482qnf5azfdmpz6"
    @nba_data = Nokogiri::HTML(open(@nba_url))
    @output_file = "nba.html"
    @gamehashes = []
    @gamesbydate = []
    @startdate = Date.new(2013,10,29)
    @enddate = Date.new(2014,04,17)
  end

  def loaddata
    games = @nba_data.css('league season-schedule games game')
    games.each do |game|
      @gamehashes << {}
      @gamehashes[-1][:hometeam] = game.css('home').attr("name")
      @gamehashes[-1][:homealias] = game.css('home').attr("alias")
      @gamehashes[-1][:awayteam] = game.css('away').attr("name")
      @gamehashes[-1][:awayalias] = game.css('away').attr("alias")
      @gamehashes[-1][:GMTdate] = Date.parse(game.attr("scheduled")[0..9])
      @gamehashes[-1][:GMTtime] = (game.attr("scheduled")[11..12] + game.attr("scheduled")[14..15]).to_i
      calc_EST
    end
  end

  def calc_EST
      @gamehashes[-1][:ESTdate] = @gamehashes[-1][:GMTdate]
      @gamehashes[-1][:ESTdate] = @gamehashes[-1][:GMTdate] - 1 if @gamehashes[-1][:GMTtime] <= 500
      @gamehashes[-1][:ESTtime] = @gamehashes[-1][:GMTtime] - 500
      @gamehashes[-1][:ESTtime] += 2400 if @gamehashes[-1][:ESTtime] < 0
      @gamehashes[-1][:ESTtime] -= 1200 if @gamehashes[-1][:ESTtime] > 1200
      @gamehashes[-1][:ESTtime] = @gamehashes[-1][:ESTtime].to_s
      @gamehashes[-1][:ESTtime] = @gamehashes[-1][:ESTtime][0..-3] + ":" + @gamehashes[-1][:ESTtime][-2..-1] + " PM"
  end

  def groupgames
    deltadays = 0 
    while @startdate + deltadays <= @enddate do
      @gamesbydate[deltadays] = []
      @gamehashes.each do |game|
        @gamesbydate[deltadays] << game if game[:ESTdate] == @startdate + deltadays
      end
      puts @gamesbydate[deltadays].size
      deltadays += 1
    end
  end

  def write_to_file
    file = File.open(@output_file, 'w')
    file.puts "<html>"
    file.puts "<head>"
    file.puts "<title=NBA Schedule 2014>"
    file.puts "</head>"
    file.puts "<body>"
    @gamesbydate.size.times do |date|
      file.puts "<div>"
      file.puts "<h3>#{@startdate+date}</h3>"
      @gamesbydate[date].each do |game|
        file.puts "<h4>#{game[:awayalias]} @ #{game[:homealias]}</h4>"
        file.puts "<p>#{game[:ESTdate]} @ #{game[:ESTtime]}</p>"
      end
      file.puts "</div>"
    end
    file.puts "</body>"
    file.puts "</html>"
  end
end

myreader = Nbareader.new
myreader.loaddata
myreader.groupgames
myreader.write_to_file