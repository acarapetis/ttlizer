import Timetable (preferences)
import Timeslots (activities)

main = putStrLn . show . preferences $ activities
