# ttlizer ###################################
### a simple timetable/schedule optimizer ###

## Introduction
`ttlizer` is designed for people who have a large number of activities (for
example, school classes) they need to attend, where they have the choice of
many timeslots for each activity/class.

Attempting to find an ideal combination of timeslots manually is a
time-consuming process that can be automated with a few simple rules.  

## Usage
While there is no graphical interface of any form, and even the basic
functionality is still under construction, there is a command-line script
(`ttlizer`) that exposes the current functionality.

The output is dependent on the task given - if none is given; it's a no-op.

Usage:
	ttlizer [options] --task=<task> [input_file]

Tasks:

- preferences: show estimated ideal timeslot preferences
- best_timetables: show the [count] highest ranking timetables
- clashes: show a histogram/frequency plot of clash counts

Options:
	--format [timeslots|dump]   : input format; default is timeslots
	--count <count>, -n <count> : used in best_timetables
	--granularity int, -g int   : stepsize for clash histogram

## Implementation
`ttlizer` currently rates combinations based on the following criteria:

- Negative weighting for activity clashes

The project is still in very early stages; planned criteria for the future:

- Negative weighting for large gaps in between activities
- Positive weighting for days with no activities scheduled

Partially implemented features:

- Generation of preference order for individual activities

Planned features:

- Customizable weighting for all criteria

## Performance Issues
`ttlizer` can take a minute or more on my machine to calculate preference order
for inputs with many (>1000) possible timetable combinations - this can be
somewhat mitigated by building a raw Marshal dump of the combinations once:
    ruby generate_timetables.rb < timeslots.yaml > timetables.dump

You can then get the results you want with `ttlizer` by specifying
`--format dump` and feeding it `timetables.dump`.

If your input file has many, many combinations (>10000 is not unreasonable -
4 activities with 10 timeslot options each would yield 10000) then the current
implementation is likely to take a really, really long time - it's a real
issue and I'm trying to think of a way around it.

I'm considering rewriting the whole thing in Haskell: 

- The nature of the problem makes a functional approach natural (in fact, my ruby implementation
is mostly functional anyway);

- I've always wanted to build something tangible in a functional language;

- From what I've heard, `ghc` spits out some pretty bloody fast code.
    

##Contact

    Anthony Carapetis
    anthony [dot] carapetis [at] gmail [dot] com
    http://github.com/amdpox
