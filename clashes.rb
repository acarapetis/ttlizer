#!/usr/bin/env ruby

=begin rdoc
     clashes.rb: generate clash histogram

     Generates a histogram of clash frequency for all possible timetables
     based on the input file (YAML formatted activities/timeslots list)

     Usage: 
        ./clashes.rb [-g granularity =1] [input_file]

     If +input_file+ is null, reads from STDIN.
=end

require 'timetable'
require 'optparse'

# Read arguments
options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"

    opts.on("-g", "--granularity [granularity]", "Count-space stepsize") do |g|
        options[:granularity] = g || 1
    end
end.parse!

granularity = options[:granularity].to_f
granularity = 1 if granularity.nil? or granularity == 0

# Load activities, generate timetables and count clashes
activities = load_activities_from_simple_yaml ARGF.read
timetables = generate_timetables(activities)
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
