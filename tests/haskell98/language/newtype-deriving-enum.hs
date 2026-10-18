{-# LANGUAGE GeneralizedNewtypeDeriving #-}
-- GeneralizedNewtypeDeriving: Enum of a newtype through its field type
newtype Age = Age Int deriving (Show, Eq, Ord, Enum, Bounded, Num)
newtype Wrap f a = Wrap (f a) deriving (Eq, Show)
newtype O = O Ordering deriving (Show, Enum)
main :: IO ()
main = do
  print ([Age 1 .. Age 3], succ (Age 9), (minBound :: Age) < 0, fromEnum (Age 5))
  print (map fromEnum [O EQ, O GT], [O LT ..])
