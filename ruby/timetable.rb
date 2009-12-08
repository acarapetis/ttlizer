#!/usr/bin/env ruby

=begin rdoc
timetable.rb: core library

This is the guts of ttlizer - class definitions, utility functions, and the
analysis routines.
=end

require 'yaml'

DAYS = [ 
    :monday, 
    :tuesday, 
    :wednesday, 
    :thursday, 
    :friday, 
    :saturday, 
    :sunday 
]

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

    # Number of days with no classes
    def days_off
        (DAYS - @times.map(&:day).uniq).length
    end

    # Total hours away from 'home' including gaps
    def hours_required
        @times.map(&:day).uniq.map {|day|
            timeslots = @times.select {|t| t.day == day}
            start  = timeslots.min_by {|t| t.time }
            finish = timeslots.max_by {|t| t.time + t.length }
            finish.time + finish.length - start.time
        }.inject(&:+)
    end

    # Flat ASCII Timetable with details
    def detailed_text
        @times.sort.map do |t| 
            clash = ( @times.map{ |a| a.overlap? t }.count(true) > 1 )
            "#{t} #{ clash ? 'CLASH' : '' }"
        end.join "\n"
    end
    
    # Calendar-style layout (just a data structure)
    # returns: {
    #   :start    => first hour,
    #   :end      => last hour,
    # },
    # [
    #   { # first day
    #       :text   => text,
    #       :length => length,
    #   }, #...
    # ]
    def calendar_layout
        info = {
            :start    => @times.map{|t| t.time}.min,
            :end      => @times.map{|t| t.time + t.length}.max,
        }
        day_length = info[:end] - info[:start]

        ret = DAYS.map do |day|
            day_timeslots = @times.select{|t| t.day == day}.sort_by{|t| t.time}
            if day_timeslots.length == 0
                [{ :text => '', :length => day_length }]
            else
                r = []
                t = info[:start]
                while t < info[:end]
                    sl = day_timeslots.shift
                    if sl.nil?
                        r << { :text => '', :length => info[:end] - t }
                        break
                    else
                        r << { :text => '', :length => sl.time - t } if sl.time > t
                        r << { :text => sl.activity, :length => sl.length }
                        t = sl.time + sl.length
                    end
                end
                r
            end
        end
        return info, ret
    end

    def html_calendar(stepsize)
        info, data = calendar_layout

        ret = %w{<table> <tr>}
        ret << '<th>DAY\time</th>'
        (info[:start] .. info[:end]).step(stepsize).each do |t|
            ret << "<th>#{t}</th>"
        end
        ret << '</tr>'

        DAYS.each_with_index do |day, i|
            ret << '<tr>'
            ret << "<th>#{day}</th>"
            data[i].each do |slot|
                span, text = slot[:length] / stepsize, slot[:text]
                ct = ( slot[:text] == '' ? '' : 'class="boxed" ' )
                ret << %Q[<td #{ct}colspan="#{span.to_i}">#{text}</td>]
            end
            ret << '</tr>'
        end
        ret << '</table>'
        return ret.join "\n"
    end

    # Visual "calendar" layout of a set of timeslots (ASCII)
    def visual_layout
        ret = (0 .. 18).map{|n| sprintf "|%3i", n}.join('') + "\n"
        lines = ([[0]*19] * 5).map{|a| a.dup}
        @times.each do |t|
            (t.time.floor .. t.time.floor + t.length.floor - 1).each do |n|
                lines[DAYS.index(t.day)][n] += 1
            end
        end
        ret += lines.map{|a| a.map{|c| c.to_s * 4}.join ''}.join "\n"
        return ret
    end
end

# Generate all possible timetable combinations using the given activity set
def generate_timetables(activities)
    # First, grab the activities where there's only one choice of timeslot:
    locked_timeslots = activities.find_all{ |a| a.single_slot? }
                                 .map     { |a| a.times.first }

    combiner = lambda { |acc, act| 
        act.times.each_with_object([]) { |t, a| acc.each { |y| a << y + [t] } }
    }

    # Compute results
    activities.find_all{ |a| not a.single_slot? } # take activities with options
              .inject([[]], &combiner) # generate all the possible combinations
              .map     { |ts| Timetable.new(ts + locked_timeslots) }
              .sort_by { |timeslot| timeslot.clashes }
end

# Take an array of weights in order of importance and generate a single
# weigh index from them.
def flatten_weight(weights)
    if weights.is_a? Array then
        ret = 0
        mult = 1
        while w = weights.pop do
            ret += w * mult
            mult *= 1000
        end
        return ret
    else
        return weights
    end
end

# Use the given weight lambda to compute the weights of all timeslots in
# the set of timetables.
def compute_weights(timetables, weight)
    prelim = timetables.each_with_object({}) do |tt, data|
        tt.times.each do |ts|
            data[ts] = { :count => 0, :weight_sum => 0 } if data[ts].nil? 
            data[ts][:count] += 1
            data[ts][:weight_sum] += flatten_weight(weight.call(tt));
        end
    end

    return prelim.each_with_object({}) do |a, data|
        data[a[0]] = a[1][:weight_sum] / a[1][:count]
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

# Compile a list of timeslot preferences for each activity using a weighting
# function
# Return format: {
#   activity => [ timeslot, timeslot, ...] # sorted with best first
# }
def compute_weighted_preferences(activities, timetables, weight)
    weights = compute_weights(timetables, weight)

    return activities.each_with_object({}) do |act, ret|
        next if act.times.length < 2 
        ret[act] = act.times.sort_by { |ts| weights[ts] }
    end
end
