#!/usr/bin/env ruby

=begin rdoc
    generate_timetables.rb: generate all possible timetables and dump to Marshal

    Usage:
        ./generate_timetables.rb [input file] > file.dump
=end

require 'timetable'

activities = load_activities_from_simple_yaml ARGF.read
print Marshal.dump({
    :activities => activities,
    :timetables => generate_timetables(activities),
})
