#!/usr/bin/env ruby

require 'yaml'

DAYS = [ :monday, :tuesday, :wednesday, :thursday, :friday ]

# Convert an hour-of-day to a human-readable 24h time
def time_format(time)
    hour = time.to_i
    minute = (60*(time - hour)).to_i
    minute = "0"+minute.to_s if minute < 10
    hour   = "0"+hour.to_s   if hour < 10
    return "#{hour}:#{minute}"
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
        other > this
    end

    def <=>(other)
        return -1 if self < other
        return  1 if self > other
        return  0
    end

    # By how many hours do these two activity slots overlap?
    def overlap(other)
        a, b = self, other
        return false if a.day != b.day
        a, b = b, a if a > b

        val = a.length - (b.time - a.time)
        val = 0 if val < 0
        return val
    end

    # Do these two activities overlap?
    def overlap?(other)
        return self.overlap(other) > 0
    end

    def to_s
        return "#{activity}\t#{day.to_s.capitalize[0..2]} @ #{time_format(time)} to #{time_format(time+length)}"
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
end

# Recursively build the timetable combinations
def build_timetables(remaining_activities, timetables)
    remaining_activities = remaining_activities.dup
    this_activity = remaining_activities.shift # grab the next activity
    if timetables.length == 0 # This is the first call in the chain, just recurse with the first activity set
        return build_timetables(remaining_activities, this_activity.times.map{|x| [x]})
    elsif remaining_activities.length == 0 # This is the last call in the chain - don't recurse
        return timetables.map{ |a| this_activity.times.map{ |x| a+[x] }}.flatten(1)
    else # recurse as usual
        return build_timetables(remaining_activities, timetables.map{ |a| this_activity.times.map{ |x| a+[x] }}.flatten(1))
    end
end

# Generate all possible timetable combinations using the given activity set
def generate_timetables(activities)
    timetables = go_deeper(activities, [])
    return timetables.map { |sessions| {
        :clashes    => sessions.combination(2).map{|a,b| a.overlap(b)}.inject(&:+), # Clashing hour count
        :timetable  => sessions
    }}.sort_by {|tt| tt[:clashes]}
end

# Formatted string representation of a set of timeslots
def format_timetable(timeslots)
    timeslots.sort.join "\n"
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
