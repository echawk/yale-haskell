{-# LANGUAGE UnboxedTuples #-}
import GHC.Integer (quotRemInteger, divModInteger)
main = do
  case quotRemInteger (-7) 2 of (# q, r #) -> print (q, r)
  case divModInteger (-7) 2 of (# q, r #) -> print (q, r)
