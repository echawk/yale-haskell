{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- A pattern synonym with a view and a signature, used from
-- patsyn-typed.hs: the signature types its arguments there too.
module PatSynTyped where
import Data.Fixed (divMod')
newtype Month = MkMonth Integer
pattern YearMonth :: Integer -> Int -> Month
pattern YearMonth y my <-
    MkMonth ((\m -> divMod' m 12) -> (y, (succ . fromInteger -> my)))
  where YearMonth y my = MkMonth (y * 12 + toInteger (pred my))
