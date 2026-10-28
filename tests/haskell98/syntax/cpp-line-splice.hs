{-# LANGUAGE CPP #-}
-- A line ending in a backslash is spliced to the next, as cpp does (GHC's
-- GHC.hs); a string gap (next line starting with a backslash) is kept.
import Data.List ((\\))
main = do
  putStrLn "target FilePath not found in\
           module dependency graph"
  putStrLn "a string \
           \gap"
  print ([1, 2, 3] \\ [2 :: Int])
