-- hiding (T()) hides the type T, not its constructor T
module Main (main) where
import HidingTypeA hiding (T())
main :: IO ()
main = print (T 2)
