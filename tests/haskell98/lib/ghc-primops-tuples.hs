{-# LANGUAGE MagicHash, UnboxedTuples, TemplateHaskell #-}
module Main(main) where
import GHC.Exts
import GHC.IO (IO(..))
import Data.Array.Byte
import Language.Haskell.TH.Syntax (lift)

main :: IO ()
main = do
  r <- IO (\s -> case newMutVar# (10 :: Int) s of
    (# s1, mv #) -> case atomicModifyMutVar2# mv (\x -> (x + 1, x * 2)) s1 of
      (# s2, old, (_, d) #) -> case atomicModifyMutVar_# mv (* 3) s2 of
        (# s3, o2, n2 #) -> case casMutVar# mv n2 0 s3 of
          (# s4, flag, _ #) -> case readMutVar# mv s4 of
            (# s5, v #) -> (# s5, (old, d, o2, n2, I# flag, v) #))
  print r
  m <- IO (\s -> case newMVar# s of
    (# s1, mv #) -> case tryTakeMVar# mv s1 of
      (# s2, e, _ #) -> case putMVar# mv 'k' s2 of
        s3 -> case tryTakeMVar# mv s3 of
          (# s4, f, c #) -> (# s4, (I# e, I# f, c) #))
  print m
  print $(lift (fromList [1, 2, 250] :: ByteArray))
