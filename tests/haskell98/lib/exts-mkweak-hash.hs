{-# LANGUAGE MagicHash, UnboxedTuples #-}
import GHC.Exts
import GHC.Types

main :: IO ()
main = do
  r <- IO (\s -> case mkWeak# () "kept" (\t -> (# t, () #)) s of
                   (# s1, w #) -> case deRefWeak# w s1 of
                     (# s2, _, v #) -> (# s2, v #))
  putStrLn r
