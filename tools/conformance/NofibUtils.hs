-- A Haskell 98 stand-in for nofib's NofibUtils (which uses CPP, foldl',
-- pure and <$>).  hash gives GHC's results: nofib's hash folds over a
-- 64-bit Int and relies on its wrap-around, which Haskell 98 leaves
-- undefined (Yale Haskell's Int is the 62-bit fixnum range), so it is
-- computed on Integer modulo 2^64 and read as a signed 64-bit number.
-- salt returns its argument, as nofib's GHC branch does.
module NofibUtils (hash, salt) where

import Char (ord)

hash :: String -> Integer
hash = signed . go 0
  where go acc []     = acc
        go acc (c:cs) = let acc' = (toInteger (ord c) + acc * 31) `mod` w
                        in acc' `seq` go acc' cs
        w = 2 ^ 64
        signed h = if h >= 2 ^ 63 then h - w else h

salt :: a -> IO a
salt = return
