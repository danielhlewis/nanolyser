module GrapherHelper
  def generate_cells(statistic, stats, custom_label=nil, highlight=true)
    case statistic
      when "written_today"
        label = "Written Today"
        value = written(stats, stats[:current_day])
      when "wordcount_today"
        label = "Current Wordcount"
        value = wordcount(stats, stats[:current_day], highlight)
      when "words_remaining_today"
        label = "Words Until Today's Goal is Met"
        value = words_remaining(stats, stats[:current_day])
      when "personal_goal_today"
        label = "Today's Personalized Goal"
        value = personal_goal(stats, stats[:current_day])
      when "static_goal_today"
        label = "Today's NaNoWriMo Goal"
        value = static_goal(stats, stats[:current_day])
      when "current_streak"
        label = "Current Streak"
        value = current_streak(stats)
      when "written_goal_today"
	label = "Words Required Today"
	value = words_required(stats, stats[:current_day])
      when "overall_status"
	label = "Current Status"
	value = overall_status(stats, stats[:current_day])
      when "day_today"
	label = "Last Recorded Day"
	value = (stats[:current_day].to_i + 1).to_s
      when "words_remaining_total"
	label = "Total Words Remaining"
	value = total_words_remaining(stats, stats[:current_day])
      when "days_remaining_total"
	label = "Days Remaining"
	value = (30 - stats[:current_day].to_i - 1).to_s
      when "average_pace"
	label = "Your Average Words per Day"
	value = average_pace(stats, stats[:current_day])
      when "current_end_date"
	label = "Your Completion Date"
	value = estimate_completion_date(stats, stats[:current_day])
      when "end_date"
	label = "NaNoWriMo End Date"
	value = Date.parse("2011-11-30").to_s
    end
    if not custom_label.nil?
      label = custom_label
    end
    s = open_cells(label)
    s += value.to_s
    s += close_cells
  end
  
  def estimate_completion_date(stats, day)
    if stats[:target_wordcount].to_i < stats[:wc].to_i
      stats[:daily_stats].each_with_index do |day, day_number|
        if day[:wc].to_i > stats[:target_wordcount].to_i
          return (Date.parse("2011-11-01") + (day_number).days).to_s
        end
      end
      return "Completed!"
    else
      
      pace = average_pace(stats, day).to_i
      if pace == 0
	return "The End of Time!"
      else
	days_to_complete = (1.0 * stats[:target_wordcount] / pace).ceil
	return (Date.parse("2011-11-01") + (days_to_complete - 1).days).to_s
      end
    end
  end
  
  def average_pace(stats, day)
    if day == 0
      return stats[:daily_stats][day][:wc]
    else
      return "#{((stats[:daily_stats][day][:wc].to_i * 1.0) / (stats[:current_day].to_i + 1)).round(0).to_i}"
    end
  end
  
  def total_words_remaining(stats, day)
    words = stats[:target_wordcount] - stats[:daily_stats][day][:wc].to_i
    if words < 0
      words = 0
    end
    return "#{words}"
  end
  
  def overall_status(stats, day)
    status = stats[:daily_stats][day][:wc].to_i - stats[:daily_stats][day][:st].to_i
    if status < 0
	s = "<font color=red>#{-status} Words Behind"
    else 
      if status > 0
	s = "<font color=green>#{status} Words Ahead"
      else
	s = "Exactly on Schedule"
      end
    end    
  end
  
  def words_required(stats, day)
    if day == 0
      words = stats[:daily_stats][day][:dt]
    else
      words = stats[:daily_stats][day][:dt].to_i - stats[:daily_stats][day - 1][:wc].to_i
    end
    if words < 0
      words = 0
    end
    return "#{words}"
  end
  
  def current_streak(stats)
    if stats[:success_streak] > 0
      s = "<font color=green>#{stats[:success_streak]} Successful Day"
      if stats[:success_streak] != 1
        s += "s"
      end
      s += "</font>"
    else 
      if stats[:fail_streak] > 0
        s = "<font color=red>#{stats[:fail_streak]} Unsuccessful Day"
        if stats[:fail_streak] != 1
          s += "s"
        end
        s += "</font>"
      else
        s = "N/A"
      end
    end
  end
    
  def written(stats, day)
    if stats[:daily_stats][day][:dt].to_i > stats[:daily_stats][day][:wc].to_i
    	s = "<font color=red>"
  	else
  	  s = "<font color=green>"
	  end  
    s += "#{stats[:daily_stats][stats[:current_day]][:wc] - stats[:daily_stats][stats[:current_day]-1][:wc]}</font>"
  end
  
  def wordcount(stats, day, highlight = true)
    if highlight
      if stats[:daily_stats][day][:dt].to_i > stats[:daily_stats][day][:wc].to_i
        s = "<font color=red>"
      else
        s = "<font color=green>"
      end
      s += "#{stats[:wc]}</font>"
    else
      s = "#{stats[:wc]}"
    end
  end
  
  def words_remaining(stats, day)
    if stats[:daily_stats][day][:dt].to_i > stats[:daily_stats][day][:wc].to_i
  		s = "#{stats[:daily_stats][stats[:current_day]][:dt].to_i - stats[:wc].to_i}"
  	else
  		s = "<font color=green>Hooray, no more today!</font>"
  	end
	end
  
  def personal_goal(stats, day)
    if stats[:daily_stats][day][:dt].to_i < stats[:daily_stats][day][:st].to_i
      s = "<font color=red>"
  	else
  	  s = "<font color=green>"
	  end
	  s += stats[:daily_stats][day][:dt].to_s
  end
  
  def static_goal(stats, day)
	  stats[:daily_stats][day][:st].to_s
  end
  
  def open_cells(label)
    return "<td align=left>#{label}:</td><td align=right>"
  end
  
  def close_cells
    return " &nbsp;</td>"
  end
  
end
