#!/usr/bin/env ruby

=begin rdoc
timetable.rb: core library

This is the guts of ttlizer - class definitions, utility functions, and the
analysis routines.
=end

require 'yaml'

DAYS = [ :monday, :tuesday, :wednesday, :thursday, :friday ]

# Convert an hour-of-day to a human-readable 24h time
def time_format(time)
    hour = time.to_i
    minute = (60*(time - hour)).to_i
    sprintf "%02i:%02i", hour, minute
end

# A possible timeslot for a particular activity
class Timeslot
    attr_reader :day, :time, :length
    attr_accessor :activity

    def initialize(day, time, length)
        @day, @time, @length = day, time.to_f, length.to_f
    end

    def >(other)
        return true  if DAYS.index(self.day) > DAYS.index(other.day)
        return false if DAYS.index(self.day) < DAYS.index(other.day)
        return (self.time > other.time)
    end

    def <(other)
        other > self
    end

    def <=>(other)
        return -1 if self < other
        return  1 if self > other
        return  0
    end

    # By how many hours do these two activity slots overlap?
    def overlap(other)
        a, b = self, other
        return 0 if a.day != b.day
        a, b = b, a if a > b

        return 0                            if a.time + a.length < b.time
        return a.time - b.time + a.length   if a.time + a.length < b.time + b.length
        return b.length
    end

    # Do these two activities overlap?
    def overlap?(other)
        return self.overlap(other) > 0
    end

    def to_s
        day_str = @day.to_s.capitalize[0..2]
        start   = time_format(@time)
        finish  = time_format(@time + @length)
        return "#{activity}\t#{day_str} @ #{start} to #{finish}"
    end

    # Average number of clashes of timetables that use this timeslot
    def average_clashes(timetables)
        # Select all the timetables that include this timeslot:
        tts = timetables.select{ |t| t.times.include? self }

        # Calculate the arithmetic mean of the number of clashes:
        return tts.map{ |t| t.clashes }.inject(&:+) / tts.length
    end
end

# An activity that must be scheduled in *one* of the given timeslots
class Activity
    attr_reader :times, :name

    def initialize(name, times)
        @times = times.map do |t| 
            # Allow each element to be specified as a 2-el array
            if t.is_a? Array and t.length == 3 then
                Timeslot.new(*t)
            elsif t.is_a? Timeslot
                t
            else
                fail "Argument element #{t.inspect} is not a Timeslot (or translatable array)!"
            end
        end
        @name = name
        @times.each {|t| t.activity = name}
    end

    def single_slot?
        @times.length == 1
    end
end

# A timetable/schedule (combination of timeslots)
class Timetable
    attr_reader :times

    def initialize(times)
        @times = times
    end

    # Add a timeslot to the timetable
    def add_timeslot(timeslot)
        @times << timeslot
    end

    # Hours of clashing timeslots/sessions
    def clashes
        # TODO: investigate/fix behaviour for 3+ mutually clashing timeslots
        @times.combination(2).map{|a,b| a.overlap(b)}.inject(&:+)
    end

    # Flat ASCII Timetable with details
    def detailed_text
        @times.sort.map do |t| 
            clash = ( @times.map{ |a| a.overlap? t }.count(true) > 1 )
            "#{t} #{ clash ? 'CLASH' : '' }"
        end.join "\n"
    end

    # Visual "calendar" layout of a set of timeslots (ASCII)
    def visual_layout
        ret = (0 .. 18).map{|n| sprintf "|%3i", n}.join('') + "\n"
        lines = ([[0]*19] * 5).map{|a| a.dup}
        @times.each do |t|
            puts "#{DAYS.index(t.day)} #{t.time} #{t.length}"
            (t.time.floor .. t.time.floor + t.length.floor - 1).each do |n|
                lines[DAYS.index(t.day)][n] += 1
            end
        end
        ret += lines.map{|a| a.map{|c| c.to_s * 4}.join ''}.join "\n"
        return ret
    end
end

# Recursively build the timetable combinations
# NOTE: this modifies remaining_activities, should only be called by 
# generate_timetables or by itself
def _build_timetables(remaining_activities, timetables)
    # This implementation is *very* ugly.
    # TODO: tidy it up!
    activity = remaining_activities.shift # grab the next activity
    if timetables.length == 0 
        # This is the first call in the chain, just recurse with the first 
        # activity set:
        return _build_timetables(remaining_activities, activity.times.map{|x| [x]})
    elsif remaining_activities.length == 0 
        # This is the last call in the chain - don't recurse
        return timetables.map{ |a| activity.times.map{ |x| a+[x] }}.flatten(1)
    else 
        # recurse as usual
        return _build_timetables(remaining_activities, 
                timetables.map{ |a| activity.times.map{ |x| a+[x] }}.flatten(1))
    end
end

# Generate all possible timetable combinations using the given activity set
def generate_timetables(activities)
    locked_timeslots = activities.find_all{ |a| a.single_slot? }.map{ |a| a.times[0] }
    timetables = _build_timetables(activities.find_all { |a| not a.single_slot? }, []) 
    return timetables.map       { |timeslots| Timetable.new(timeslots + locked_timeslots) }
                     .sort_by   { |timeslot| timeslot.clashes }
end

# Compute the average clash count for each timeslot in the timetable set
def compute_average_clashes(timetables)
    # Return format:
    # {
    # timeslot => { count => n, clash_sum => n },
    # ...
    # }
    prelim = timetables.each_with_object({}) do |tt, data|
        tt.times.each do |ts|
            data[ts] = { :count => 0, :clash_sum => 0 } if data[ts].nil? 
            data[ts][:count] += 1
            data[ts][:clash_sum] += tt.clashes
        end
    end

    return prelim.each_with_object({}) do |a, data|
        data[a[0]] = a[1][:clash_sum] / a[1][:count]
    end
end

# Create array of activities from YAML (verbose format)
#
# Format:
#
#   activity_name:
#     - day:    <day_of_week>
#       time:   <hour>
#       length: <length>
#     - day:    <day_of_week>
#       time:   <hour>
#       length: <length>
def load_activities_from_verbose_yaml(yaml_str)
    YAML.load(yaml_str).map do |name,sessions| 
        Activity.new(name, sessions.map do |h| 
            [h["day"].to_sym, h["time"], h["length"]]
        end)
    end
end

# Create array of activities from YAML (simple format)
# 
# Format:
#
#   activity name:
#     - <day_of_week> <hour> <length>
#     - <day_of_week> <hour> <length>
def load_activities_from_simple_yaml(yaml_str)
    YAML.load(yaml_str).map do |name,sessions| 
        Activity.new(name, sessions.map do |h| 
            j = h.split(/\s+/)
            [j[0].to_sym, j[1], j[2]]
        end)
    end
end
