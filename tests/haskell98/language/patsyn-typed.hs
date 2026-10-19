{-# LANGUAGE PatternSynonyms #-}
-- Imported pattern synonyms with views: their signatures type the
-- arguments (no ambiguity), in equations and in lambdas.
import PatSynTyped
showMonth :: Month -> String
showMonth (YearMonth y m) = show y ++ "-" ++ show m
main :: IO ()
main = do
  putStrLn (showMonth (YearMonth 2024 2))
  print (map (\(YearMonth _ m) -> m) [YearMonth 2020 1, YearMonth 2021 12])
