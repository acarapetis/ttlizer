-- {{{ Exports
module Timetable
( Activity(..)
, Timeslot(..)
, DayTime(..)
, Day(..)
, overlap
, clashes
, averageClashes
, newActivity
, possibleTimetables
, freqCount
, histogram
, preferences
) where
-- }}}

-- {{{ Imports
import Data.Function (on)
import Data.List (tails, genericLength, intercalate, sortBy)
import qualified Data.Map as Map (Map, empty, fromList, insert, lookup, keys, elems, findMax, findMin)
-- }}}

-- {{{ Datatypes
data Day = Mon | Tue | Wed | Thu | Fri | Sat | Sun
    deriving (Eq, Ord, Show, Read, Enum, Bounded)

data DayTime   = DayTime {
    day  :: Day,
    hour :: Float
} deriving (Eq, Ord, Show, Read)

data Timeslot  = Timeslot {
    time          :: DayTime,
    duration      :: Float,
    activityName :: String
} deriving (Eq, Show)

data Activity  = Activity {
    name  :: String,
    slots :: [Timeslot]
} deriving (Eq, Show)
-- }}}

-- {{{ Main analysis functions
preferences :: [Activity] -> Map.Map String [Timeslot]
preferences activities = foldr f Map.empty activities
    where f act acc            = Map.insert (name act) (blah act) acc
          blah (Activity _ ss) = sortBy (compare `on` (\t -> averageClashes t timetables)) ss
          timetables           = possibleTimetables activities

possibleTimetables :: [Activity] -> [[Timeslot]]
possibleTimetables = foldr combos [[]]
    where combos act acc = [x:y | x <- slots act, y <- acc]
-- }}}

-- {{{ Timetable-specific utility functions
overlap :: Timeslot -> Timeslot -> Float
overlap s1@(Timeslot t1@(DayTime d1 h1) l1 _) 
        s2@(Timeslot t2@(DayTime d2 h2) l2 _)
            | t1 > t2       = overlap s2 s1
            | d1 /= d2      = 0
            | h1+l1 < h2    = 0
            | h1+l1 < h2+l2 = h1 - h2 + l1
            | otherwise     = l2

isOverlap :: Timeslot -> Timeslot -> Bool
isOverlap s1 s2 = overlap s1 s2 /= 0

clashes :: [Timeslot] -> Float
clashes [s] = 0
clashes ss  = sum . map overlappage $ combinations 2 ss
    where overlappage [a,b] = overlap a b

-- compute average number of clashes in timetables that use this timeslot
averageClashes :: Timeslot -> [[Timeslot]] -> Float
averageClashes s =
    average . map clashes . filter (elem s)

-- newActivity: overrides specified Timeslot activityName 
newActivity :: String -> [String -> Timeslot] -> Activity
newActivity n fs = Activity n (map (\f -> f n) fs)
    --where addname (Timeslot t l _) = Timeslot t l n
-- }}}

-- {{{ Generic utility functions
average :: (Fractional a) => [a] -> a
average xs = sum xs / genericLength xs

combinations :: Int -> [a] -> [[a]]
combinations 0 _  = [ [] ]
combinations n xs = [ y:ys | y:xs' <- tails xs
                           , ys <- combinations (n-1) xs']

freqCount :: (Ord a) => [a] -> Map.Map a Int
freqCount xs = foldr f Map.empty xs
    where f item acc = case Map.lookup item acc of
                       Nothing -> Map.insert item 1     acc
                       Just x  -> Map.insert item (x+1) acc
-- }}}

-- {{{ ASCII Histogram fuction
-- Generates a horizontal ASCII histogram from a frequency map
-- Feed it freqCount
histogram :: (Num k, Enum k, Ord k) => k -> Map.Map k Int -> String
histogram stepSize freqs =
    let lowest  = minimum . Map.keys $ freqs
        highest = maximum . Map.keys $ freqs
        krange  = [lowest, lowest+stepSize .. highest]
    in intercalate "\n" . map mapper $ krange
    where hashbar Nothing  = ""
          hashbar (Just x) = replicate (floor . (*mult) . fromIntegral $ x) '#'
          hashline n x = show n ++ "\t: " ++ show x ++ "\t" ++ hashbar x
          mapper n = (hashline n (Map.lookup n freqs))
          mult = (40.0/) . fromIntegral . maximum . Map.elems $ freqs
-- }}}

-- vim: ai: foldmethod=marker
