-- A hand-written Show instance using showsPrec and showParen, used
-- inside a derived Show instance and in a list.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data V = V Int Int

instance Show V where
  showsPrec d (V x y) = showParen (d > 10) (showString "vec " . shows x . showChar ' ' . shows y)

data Box = Box V deriving Show

out :: String
out = unlines [ show (V 1 2), show (Box (V 3 4)), show [V 5 6], shows (V 7 8) "!" ]

main = appendChan stdout out abort done
