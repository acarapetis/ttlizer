#!/usr/bin/env ruby

=begin rdoc
ttcli.rb: CLI formatting functions for ttlizer

This is a library full of functions to show analysis results at the command
line - it basically encapsulates the logic and formatting from the old
individual scripts (+clashes.rb+, +best_timetables.rb+, etc)
=end

require 'timetable'

def display_preferences(activities, timetables)
    #p compute_preferences(activities, timetables)
    puts compute_preferences(activities, timetables).map{ |a, ts|
        "#{a.name}:\n" + ts.each_with_index.map{ |t, i| 
            n = sprintf "%2i", i+1
            "\t#{n}: #{t}"
        }.join("\n")
    }.join("\n")
end

def show_best_timetables(timetables, count)
    puts timetables.sort_by{ |tt| tt.clashes }
                   .first(count)
                   .each_with_index.map { |tt, i|
                       "Timetable ##{i+1}:\n" + tt.detailed_text 
                   }.join("\n\n")
end

def show_clash_histogram(timetables, granularity)
    clashes = timetables.map { |tt| tt.clashes }

    # Build histogram from array of clash counts
    clash_frequencies = (clashes.min.floor .. clashes.max.floor)
        .step(granularity)
        .each_with_object({}) { |n, h| # map to hash
            h[n] = clashes.count{ |c| n <= c and c < n+granularity }
        }

    # Calculate scaling parameter for ASCII histogram
    chars_per_count = (40.0/clash_frequencies.values.max)

    # Output
    puts "clashes freq"
    clash_frequencies.each do |n, c|
        puts "#{sprintf('%7.1f',n)} #{sprintf('%4i',c)} #{'#' * (c * chars_per_count).to_i}"
    end
end
