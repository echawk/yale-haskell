-- Two where clauses bind the same name to a constant; the optimizer
-- lifts both to the top level (GHC's utils/deriveConstants).
f :: Int -> String
f n = xs
    where xs = unlines (headers ++ footers)
          headers = ["a"
                    ,"b"]
          footers = ["  } deriving Read"]

g :: Int -> String
g n = xs
    where xs = unlines (headers ++ footers)
          headers = ["c"]
          footers = ["  }"]

main :: IO ()
main = putStr (f 1 ++ g 2)
