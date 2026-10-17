-- module M () where; INLINE with GHC phase control.
import EmptyExportOrphan ()

f :: Int -> Int
f = (+ 1)
{-# INLINE [0] f #-}

g :: Int -> Int
g = f
{-# INLINE [~1] g #-}

main :: IO ()
main = print (g 2) >> putStrLn (show not)
