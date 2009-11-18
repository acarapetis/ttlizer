#!/usr/bin/env ruby

=begin rdoc
     best_timetable.rb: find and display the "best" timetable

     Displays the best possible timetable based on the following criteria:
        - Minimum clashing hours

     Usage: 
        ./clashes.rb [input_file]

     If +input_file+ is null, reads from STDIN.
=end

require 'timetable'

# Load activities and generate timetables
activities = load_activities_from_simple_yaml ARGF.read
timetables = generate_timetables(activities)

# Minimise clashing hours
best = timetables.min{ |a,b| a.clashes <=> b.clashes }

puts "Best timetable (#{best.clashes} clashing hours):"
puts best.detailed_text
