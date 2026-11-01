{-# LANGUAGE QualifiedDo #-}
import qualified Prelude as O
import Prelude

main :: IO ()
main = do
  print (O.do { x <- [1, 2]; y <- [10, 20]; O.return (x + y :: Int) })
  O.do
    putStrLn "one"
    putStrLn "two"
