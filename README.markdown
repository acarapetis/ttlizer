# ttlizer ###################################
### a simple timetable/schedule optimizer ###

## Introduction
ttlizer is designed for people who have a large number of activities (for
example, school classes) they need to attend, where they have the choice of
many timeslots for each activity/class.

Attempting to find an ideal combination of timeslots manually is a
time-consuming process that can be automated with a few simple rules.  

## Usage
While there is no graphical interface of any form, and even the basic
functionality is still under construction, there are a few working scripts
that provide some helpful information.  They all read an activity description
file (see Input Format) as their primary argument (or from STDIN).

- `clashes.rb`: generate a histogram of clash frequency for all possible timetables
- `best_timetable.rb`: find the best-rated possible timetable and display it
- `preferences.rb`: generate a list of preferences for each activity (NOTE: preference listing is very naïve; I do not recommend you follow it blindly.)

## Implementation
ttlizer currently rates combinations based on the following criteria:

- Negative weighting for activity clashes

The project is still in very early stages; planned criteria for the future:

- Negative weighting for large gaps in between activities
- Positive weighting for days with no activities scheduled

Partially implemented features:

- Generation of preference order for individual activities

Planned features:

- Customizable weighting for all criteria

Contact:
Anthony Carapetis
anthony [dot] carapetis [at] gmail [dot] com
http://github.com/amdpox
