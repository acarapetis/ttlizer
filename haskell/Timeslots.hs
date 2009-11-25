-- Timeslots.hs: dummy data for testing
module Timeslots
( activities
) where

import Timetable
fluids = [
	Timeslot (DayTime Mon 8)  2,
	Timeslot (DayTime Mon 10) 2,
	Timeslot (DayTime Mon 13) 2,
	Timeslot (DayTime Tue 8)  2,
	Timeslot (DayTime Tue 10) 2,
	Timeslot (DayTime Tue 13) 2,
	Timeslot (DayTime Wed 8)  2,
	Timeslot (DayTime Wed 10) 2,
	Timeslot (DayTime Wed 13) 2]

maths = [
	Timeslot (DayTime Mon 8)  2,
	Timeslot (DayTime Mon 10) 2,
	Timeslot (DayTime Mon 13) 2,
	Timeslot (DayTime Tue 8)  2,
	Timeslot (DayTime Tue 10) 2,
	Timeslot (DayTime Tue 13) 2,
	Timeslot (DayTime Wed 8)  2,
	Timeslot (DayTime Wed 10) 2,
	Timeslot (DayTime Wed 13) 2]

physics = [
	Timeslot (DayTime Mon 8)  3,
	Timeslot (DayTime Mon 14) 3,
	Timeslot (DayTime Tue 8)  3,
	Timeslot (DayTime Tue 14) 3]

astro = [
	Timeslot (DayTime Mon 8)  2,
	Timeslot (DayTime Mon 10) 2,
	Timeslot (DayTime Tue 8)  2,
	Timeslot (DayTime Tue 10) 2,
	Timeslot (DayTime Wed 8)  2,
	Timeslot (DayTime Wed 10) 2,
	Timeslot (DayTime Thu 8)  2,
	Timeslot (DayTime Thu 10) 2,
	Timeslot (DayTime Fri 9)  2,
	Timeslot (DayTime Fri 11) 2]

activities = [
	newActivity "Maths Lab"		maths,
	newActivity "Physics Lab"	physics,
	newActivity "Fluids Tut"	fluids,
	newActivity "Astro Lab"		astro ]
