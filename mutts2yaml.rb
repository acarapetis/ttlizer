#!/usr/bin/ruby

=begin rdoc
mutts2yaml.rb: converts MUTTS flat HTML timetable to YAML activity input file

MUTTS is the Monash University TimeTable System - odds are this script is
useless to you.  If you're at Monash, you're in luck - also, hah, small world.

Usage:
    ./mutts2yaml.rb < saved-mutts-timetable.html > my-activities.yaml
=end

require 'yaml'

# I know, I know, I'm parsing HTML; but I know my input structure, and this
# was written in 5 minutes. Hey, at least I use //x.

html = ARGF.read
data = html.scan(%r{
    input\s+id="( [^"]+ )" # Capture Activity id
    .*?                    # And then later on in the line..
    ( fri | mon | tue | wed | thu | sat | sun ) # Capture the day
    .*?                    # And then later on in the line..
    ( \d+:\d+ )            # Capture the starting time...
    (?: &nbsp; | \s* )     # ...some filler...
    (AM|PM)                # capture AM/PM-ness
    .*?                    # Later on...
    ( [\d\.]+ )            # Capture length in hours
    (?: &nbsp; | \s* )hr   # Make sure we grabbed the right number for hours
}ixms)

# We now an array of arrays, data for each timeslot is:
# [ name, day, 12h_time, am/pm, length ]

daysyms = {
    'mon' => :monday,
    'tue' => :tuesday,
    'wed' => :wednesday,
    'thu' => :thursday,
    'fri' => :friday,
    'sat' => :saturday,
    'sun' => :sunday
}

activities = data.each_with_object({}) do |d, a|
    name, day, time, ampm, length = *d

    # Get rid of unique-ids on labs/support classes
    name.sub!(%r{ / [^/]* $}x, '') unless name =~ /Lecture/i

    day = daysyms[day.downcase].to_s
    time = time.to_f
    length = length.to_f

    time += 12 if ampm =~ /PM/i and time != 12
    
    a[name] = [] if a[name].nil?
    a[name] << [day, time, length].join(' ')
end

print YAML.dump activities
