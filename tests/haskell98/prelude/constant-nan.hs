module Main (main) where
nan :: Double
nan = 0.0 / 0.0
inf :: Double
inf = 1.0 / 0.0
main :: IO ()
main = print (isNaN nan, inf)
