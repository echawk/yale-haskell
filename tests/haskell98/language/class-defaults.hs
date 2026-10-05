-- Single-parameter type classes with default methods: defaults that
-- call other methods, instances overriding some defaults, and a pair
-- of mutually defined defaults (as in Eq) where each instance gives one.
module Main where

class Shape a where
  area     :: a -> Int
  name     :: a -> String
  name _   = "shape"
  describe :: a -> String
  describe x = name x ++ " of area " ++ show (area x)

data Square = Square Int
data Rect   = Rect Int Int

instance Shape Square where
  area (Square s) = s * s
  name _          = "square"

instance Shape Rect where
  area (Rect w h) = w * h

class Same a where
  same, differ :: a -> a -> Bool
  same x y   = not (differ x y)
  differ x y = not (same x y)

instance Same Bool where
  same = (==)

instance Same Char where
  differ = (/=)

out :: String
out = unlines [ describe (Square 3)
              , describe (Rect 2 5)
              , show (same True True, differ True False)
              , show (same 'a' 'b', differ 'a' 'a') ]

main = appendChan stdout out abort done
