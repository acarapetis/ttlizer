module Main (main) where
 
import System.Console.GetOpt
import System
import Control.Monad
import IO
import List
import Char

import Timetable (preferences)
import Timeslots (activities)

-- {{{ Command-line options
-- Thanks to haskell.org/haskellwiki/High-level_option_handling_with_GetOpt
-- for the option-handling technique

data Options = Options  { optVerbose    :: Bool
                        , optInput      :: IO String
                        , optCount      :: Int
                        , optStepsize   :: Float
                        }

defaultOptions :: Options
defaultOptions = Options    { optVerbose    = False
                            , optInput      = getContents
                            , optCount      = 1
                            , optStepsize   = 1.0
                            }

options :: [ OptDescr (Options -> IO Options) ]
options =
    [ Option "i" ["input"]
        (ReqArg
            (\arg opt -> return opt { optInput = readFile arg })
            "FILE")
        "Input file (or STDIN if not specified)"
 
    , Option "n" ["count"]
        (ReqArg
            (\arg opt -> return opt { optCount = (read arg) :: Int }) 
            "COUNT")
        "Number of timetables to display (with --task=best)"

    , Option "s" ["stepsize"]
        (ReqArg
            (\arg opt -> return opt { optStepsize = read arg :: Float })
            "NUM")
        "Granulation of histogram (with --task=clashes)"
 
    , Option "v" ["verbose"]
        (NoArg
            (\opt -> return opt { optVerbose = True }))
        "Enable verbose messages"
 
    , Option "V" ["version"]
        (NoArg
            (\_ -> do
                hPutStrLn stderr "ttlizer pre-alpha"
                exitWith ExitSuccess))
        "Print version"
 
    , Option "h" ["help"]
        (NoArg
            (\_ -> do
                prg <- getProgName
                hPutStrLn stderr (usageInfo prg options)
                exitWith ExitSuccess))
        "Show this help"
    ]

-- }}}

--main = putStrLn . show . preferences $ activities

main = do
    args <- getArgs
 
    -- Parse options, getting a list of option actions
    let (actions, nonOptions, errors) = getOpt RequireOrder options args
 
    -- Here we thread startOptions through all supplied option actions
    opts <- foldl (>>=) (return defaultOptions) actions
 
    let Options { optVerbose  = verbose
                , optInput    = input
                , optCount    = count
                , optStepsize = stepsize } = opts
 
    when verbose (hPutStrLn stderr "debug: Verbose is On")
 
    -- input >>= output
    putStrLn . show . preferences $ activities

-- vim: set foldmethod=marker
