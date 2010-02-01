# ttlizer #################
### Ruby Implementation ###

## Introduction
This is the ruby implementation of ttlizer, which I thought would probably not be of much
use for much longer - but the Haskell implementation isn't usable yet, and this is (after
a fashion).

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
