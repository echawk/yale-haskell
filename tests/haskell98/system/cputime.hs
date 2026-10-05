-- CPUTime: getCPUTime is non-negative and non-decreasing, and grows
-- by at least cpuTimePrecision over a busy loop.
module Main where

import CPUTime

put :: String -> IO ()
put s = appendChan stdout s abort done

busy :: Int -> Int
busy n = length (filter (\i -> i `mod` 7 == 3) [1..n])

main :: IO ()
main =
  getCPUTime `thenIO` \t0 ->
  put ("precision positive: " ++ show (cpuTimePrecision > 0) ++ "\n") `thenIO_`
  put ("precision at most 1s: " ++ show (cpuTimePrecision <= 1000000000000) ++ "\n") `thenIO_`
  put ("t0 >= 0: " ++ show (t0 >= 0) ++ "\n") `thenIO_`
  put ("work: " ++ show (busy 300000) ++ "\n") `thenIO_`
  getCPUTime `thenIO` \t1 ->
  getCPUTime `thenIO` \t2 ->
  put ("non-decreasing: " ++ show (t0 <= t1 && t1 <= t2) ++ "\n") `thenIO_`
  put ("advanced: " ++ show (t2 - t0 >= cpuTimePrecision) ++ "\n")
