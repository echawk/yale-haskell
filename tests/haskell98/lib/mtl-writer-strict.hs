module Main (main) where
import Control.Monad.Writer.Strict
main :: IO ()
main = print (runWriter (tell [1 :: Int] >> tell [2] >> return True))
