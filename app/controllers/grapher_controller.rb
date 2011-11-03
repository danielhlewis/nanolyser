class GrapherController < ApplicationController

  def index
#     redirect_to url_for(:controller => "grapher", :action => "show", :id=>"427542")
  end
  

  def show
    @data = {}
    if params[:id].blank?
      params[:id] = "-1"
    end
#     427542
#     params[:id]
    if params[:target].blank?
      @data[:stats], @error = parse_data(params[:id])
    else
      @data[:stats], @error = parse_data(params[:id], params[:target].to_i)
    end
    if @error.nil?
#       @data[:main_graph] = open_flash_chart_object(800,600,url_for(:controller => "grapher", :action => "graph_code", :days => @data[:stats][:daily_stats]))
#       @data[:weekday_graph] = open_flash_chart_object(600,450,url_for(:controller => "grapher", :action => "weekday_pie_graph_code", :weekdays => @data[:stats][:weekday_stats]))
        @flot_data = make_flot
    end
  end
  
  def parse_data(id, target_wordcount=50000)
    # My Id = 427542
    require 'net/http'
    require 'uri'
    #require 'xml'
    
    xml = Net::HTTP.get URI.parse("http://www.nanowrimo.org/wordcount_api/wchistory/#{id}")
    
#     xml = '<?xml version="1.0" standalone="yes"?><!DOCTYPE wchistory [
#                   <!ELEMENT wchistory (uid, error, uname, user_wordcount, wordcounts)>
#                   <!ELEMENT uid (#PCDATA)>
#                   <!ELEMENT error (#PCDATA)>
#                   <!ELEMENT uname (#PCDATA)>
#                   <!ELEMENT user_wordcount (#PCDATA)>
#                   <!ELEMENT wordcounts (wcentry+)>
#                   <!ELEMENT wcentry (wc,wcdate)>
#                   <!ELEMENT wc (#PCDATA)>
#                   <!ELEMENT wcdate (#PCDATA)>
#                 ]>
#                 <wchistory>
#                 <uid>427542</uid>
#                 <uname>coolest_moniker_ever</uname>
#                 <user_wordcount>7803</user_wordcount>
#                 <wordcounts>
#                 <wcentry>
#                 <wc>1803</wc>
#                 <wcdate>2011-11-01</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>2803</wc>
#                 <wcdate>2011-11-02</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>5803</wc>
#                 <wcdate>2011-11-03</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>7803</wc>
#                 <wcdate>2011-11-04</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>7803</wc>
#                 <wcdate>2011-11-05</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>7803</wc>
#                 <wcdate>2011-11-06</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>9803</wc>
#                 <wcdate>2011-11-07</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>12803</wc>
#                 <wcdate>2011-11-08</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>15803</wc>
#                 <wcdate>2011-11-09</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>21803</wc>
#                 <wcdate>2011-11-10</wcdate>
#                 </wcentry>
#                 <wcentry>
#                 <wc>21803</wc>
#                 <wcdate>2011-11-11</wcdate>
#                 </wcentry>
#                 </wordcounts>
#                 </wchistory>'
    
    doc = Hpricot.XML(xml)
    
    if doc.at("uname").nil?
      return nil, "Invalid id: #{id}"
    end
    
    username = doc.at("uname").inner_html
    wordcount = doc.at("user_wordcount").inner_html

    wcentries = []
    (doc/"//wchistory/wordcounts/wcentry").each do |p|
      wcentries << {:date => p.find_element("wcdate").inner_html, :wc => p.find_element("wc").inner_html.to_i}
    end
    
#     parser, parser.string = XML::Parser.new, xml
#     doc, wcentries = parser.parse, []
#     puts xml
# 
#     if doc.find('//wchistory/uname').first.nil?
#       return nil, "Invalid id: #{id}"
#     end
#     
#     username = doc.find('//wchistory/uname').first.content.strip
#     wordcount = doc.find('//wchistory/user_wordcount').first.content.strip
# 
#     doc.find('//wchistory/wordcounts/wcentry').each do |p|
#       wcentries << {:date => p.find("wcdate").first.content.strip, :wc => p.find("wc").first.content.strip.to_i}
#     end

    stats = {:username => username, :wc => wordcount}
    
    #figure out what the last recorded day is
    stats[:current_day] = (Date.parse(wcentries[wcentries.size - 1][:date]) - Date.parse("November 1, 2011")).to_i
    
    wordcounts = []
    (0..stats[:current_day]).each do |day|
      wordcounts << 0
    end
    
    wcentries.each do |e|
      wordcounts[(Date.parse(e[:date]) - Date.parse("November 1, 2011")).to_i] = e[:wc]
    end
    
    last_wordcount = 0
    wordcounts.each do |e|
      if e == 0
        e = last_wordcount
      else
        last_wordcount = e
      end
    end
    
    #stats[:current_day] = wordcounts.size - 1

    
    #Calculate Daily Statistics
#     target_wordcount = 50000
    number_of_days = 30
    max_success_streak = 0
    max_fail_streak = 0
    success_streak = 0
    fail_streak = 0
    days_ahead = 0
    days_behind = 0
    successful_days = 0
    unsuccessful_days = 0
    days = []
    number_of_days.times do |i|
      day = {:date => Date.parse("2011-11-#{i + 1}")}
      day[:st] = ((target_wordcount / (number_of_days * 1.0)) * (i + 1)).round(0).to_i
      if (wordcounts.size > i)
        day[:wc] = wordcounts[i]
        if i == 0
          day[:dt] = day[:st]
        else
          day[:dt] = (target_wordcount - wordcounts[i-1] > 0) ? ((target_wordcount - wordcounts[i-1]) / (number_of_days - i * 1.0)).round(0).to_i + wordcounts[i-1] : target_wordcount
        end
      else
              day[:wc] = 0
        if i == 0
          day[:dt] = day[:st]
        else
          day[:dt] = (target_wordcount - days[i-1][:dt] > 0) ? ((target_wordcount -  days[i-1][:dt]) / (number_of_days - i * 1.0)).round(0).to_i + days[i-1][:dt] : target_wordcount
        end
      end
      if i <= stats[:current_day]
        if (day[:wc] >= day[:st])
          # surpassed static goal
          days_ahead += 1
        else
          if i != stats[:current_day]
            #never count a day as a failure until its over
            days_behind += 1
          end
        end
        if (day[:wc] >= day[:dt])
              # surpassed goal
              successful_days += 1
                success_streak += 1
                max_success_streak = (success_streak > max_success_streak) ? success_streak : max_success_streak
                fail_streak = 0
        else
                # failed goal
                if i != stats[:current_day]
                  #never count a day as a failure until its over
                  unsuccessful_days += 1
                success_streak = 0
                fail_streak += 1
                max_fail_streak = (fail_streak > max_fail_streak) ? fail_streak : max_fail_streak
                end
        end
      end
      days << day
    end
    stats[:daily_stats] = days
    
    # Generate analysis by weekday
    weekday_stats = {}
    weekday_names = %w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
    weekday_names.each do |w|
       weekday_stats[w] = {:written => 0, :successes => 0, :failures => 0, :pending => 0} 
    end
    (stats[:current_day] + 1).times do |i|
      day = days[i]
      if i == 0
        written = day[:wc]
      else
        written = day[:wc] - days[i-1][:wc]
      end
      current_weekday_name = weekday_names[(Date.parse("2011-11-01") + i.days).cwday - 1]
      weekday_stats[current_weekday_name][:written] += written
      if day[:wc] >= day[:dt]
        weekday_stats[current_weekday_name][:successes] += 1
      else
        if day[:wc] < day[:dt] and i != stats[:current_day]
          weekday_stats[current_weekday_name][:failures] += 1
        else
          weekday_stats[current_weekday_name][:pending] += 1
        end
      end
    end
    
    stats[:weekday_stats] = weekday_stats
    stats[:target_wordcount] = target_wordcount
    stats[:max_success_streak] = max_success_streak
    stats[:max_fail_streak] = max_fail_streak
    stats[:success_streak] = success_streak
    stats[:fail_streak] = fail_streak  
    stats[:days_ahead] = days_ahead
    stats[:days_behind] = days_behind  
    stats[:successful_days] = successful_days
    stats[:unsuccessful_days] = unsuccessful_days                                                                                                                
    
    return stats, nil
  end
  
  
  
  def make_flot
    above_dynamic = []
    above_static = []
    below_static = []
    dynamic_goals = []
    static_goals = []
  
    # days = params[:stats][:daily_stats]
    # target = params[:stats][:target_wordcount].to_i
    # wordcount = params[:stats][:wc].to_i
    days = @data[:stats][:daily_stats]
    target = days.last[:st].to_i #params[:current_final_target].to_i
    wordcount = 0 #params[:current_wordcount].to_i
    # return render :text => days
    
    days.each do |day|
      day[:wc] = day[:wc].to_i
      day[:dt] = day[:dt].to_i
      day[:st] = day[:st].to_i
      if (day[:wc] >= day[:dt])
        # surpassed goal
        above_dynamic << [day[:date].beginning_of_day, day[:wc]]
      elsif (day[:wc] >= day[:st])
        # failed goal
        above_static << [day[:date].beginning_of_day, day[:wc]]
      else
        below_static << [day[:date].beginning_of_day, day[:wc]]
      end
      dynamic_goals << [day[:date].beginning_of_day, day[:dt]]
      static_goals << [day[:date].beginning_of_day, day[:st]]
      if day[:wc] != 0
        wordcount = day[:wc]
      end
    end
    
    min_days = 30
    
    convert_entry_dates_from_ruby_to_javascript([above_dynamic, above_static, below_static, static_goals, dynamic_goals])
      
    flot_data = {}
    if above_dynamic.size() > 0 or above_static.size() > 0 or below_static.size() > 0
      flot_data[:above_dynamic] = {:label => "Mission Accomplished", :data => above_dynamic}
      flot_data[:above_static] = {:label => "Ahead of Schedule", :data => above_static}
      flot_data[:below_static] = {:label => "Behind Schedule", :data => below_static}
    end
    flot_data[:static_goal] = {:label => "Static Goal", :data => static_goals}
    flot_data[:dynamic_goal] = {:label => "Dynamic Goal", :data => dynamic_goals}
    return flot_data
    
#     @flot = TimeFlot.new(:xaxis) do |f|
#       # Default colors:
#       # Gold: "#edc240",
#       # Light Blue: "#afd8f8"
#       # Red: "#cb4b4b"
#       # Green: "#4da74d"
#       # Purple: "#9440ed"
#       f.grid :hoverable => true
#       f.legend :position => "nw"
#       
#       f.bars    :barWidth => 0.94.day * TimeFlot::JS_TIME_MULTIPLIER
#       f.xaxis   :mode => "time", :minTickSize => [1, "day"], :timeformat => "%m/%d"
#       
#       f.series("Mission Accomplished", above_dynamic, :bars => {:show => true, :align => "center"}, :color => "#4da74d")
#       f.series("Ahead of Schedule", above_static, :bars => {:show => true, :align => "center"}, :color => "#edc240")
#       f.series("Behind Schedule", below_static, :bars => {:show => true, :align => "center"}, :color => "#cb4b4b")
#       f.series("Static Goal", static_targets, :color => "#777777")
#       f.series("Dynamic Goal", dynamic_targets, :color => "#8fb8ff")
#     end
  end
  
  def convert_entry_dates_from_ruby_to_javascript(entry_list)
    entry_list.each do |entries|
      entries.each do |e|
        e[0] = e[0].to_time.utc.beginning_of_day.to_i * 1000
      end
    end                                        
  end
  
  
end





