module Main (main) where
import Control.Monad.Except
import Control.Monad.Writer
type P = ExceptT String (Writer [Int])
warn :: Int -> P ()
warn = tell . pure
main :: IO ()
main = print (runWriter (runExceptT (warn 3 >> warn 4)))
