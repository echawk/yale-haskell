-- Helper for system.hs (not a test by itself): prints its program
-- name and arguments, then exits with the code given as the first
-- argument.
module Main where

import Prelude hiding (getArgs, getProgName, getEnv)
import System

main :: IO ()
main = getProgName `thenIO` \name ->
       getArgs `thenIO` \args ->
       appendChan stdout (name ++ concat (map (\a -> " <" ++ a ++ ">") args) ++ "\n")
         abort (exitWith (code args))

code :: [String] -> ExitCode
code ("0":_) = ExitSuccess
code (n:_)   = ExitFailure (read n)
code []      = ExitSuccess
