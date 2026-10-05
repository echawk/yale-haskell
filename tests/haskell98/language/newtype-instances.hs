-- A newtype is a distinct type: it can have class instances that
-- differ from those of the type it wraps.
module Main where

class Describe a where
  describe :: a -> String

newtype Celsius = Celsius Int
newtype Reversed = Reversed String

instance Describe Int where
  describe n = "int " ++ show n

instance Describe Celsius where
  describe (Celsius n) = show n ++ " degrees"

instance Describe Reversed where
  describe (Reversed s) = reverse s

instance Eq Reversed where
  Reversed a == Reversed b = a == reverse b

out :: String
out = unlines [ describe (21 :: Int), describe (Celsius 21), describe (Reversed "olleh")
              , show (Reversed "abc" == Reversed "cba") ]

main = appendChan stdout out abort done
