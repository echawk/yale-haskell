{-# LANGUAGE MagicHash, UnboxedTuples #-}
import GHC.Types
import GHC.Prim

main :: IO ()
main = do
  let IO act = putStrLn "hi"
  IO (\s -> act s)
