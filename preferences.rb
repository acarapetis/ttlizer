#!/usr/bin/env ruby

=begin rdoc
    preferences.rb: generate preferences for each activity

    Usage: 
        ./preferences.rb [input_file]
=end

require 'timetable'

# Load data, generate stats
acts = load_activities_from_simple_yaml ARGF.read
tts  = generate_timetables acts
aves = compute_average_clashes tts

acts.each do |act|
    # Preferences are only useful for activities with more than one available timeeslot
    next if act.times.length < 2 

    puts "#{act.name}:"

    # Format, sort and display
    act.times.map { |ts|
        day_str = ts.day.capitalize[0..2]
        time_str = time_format ts.time
        [aves[ts], "#{day_str} #{time_str}"]
    }.sort_by { |e|
        e[0] # sort by average clash count, ascending
    }.each_with_index { |e, i|
        n = sprintf "%2i", i+1
        puts "\t#{n}: #{e[1]}"
    }
end
