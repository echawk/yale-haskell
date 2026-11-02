{-# LANGUAGE PatternSynonyms #-}
import Data.Tuple
import GHC.Tuple (getSolo)
main = do
  print (getSolo (fmap (+1) (MkSolo (1 :: Int))), MkSolo "a" <> MkSolo "b")
  case Solo (3 :: Int) of Solo n -> print n
