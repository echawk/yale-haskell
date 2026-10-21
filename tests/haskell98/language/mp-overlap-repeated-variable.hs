{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts #-}
-- Overlapping instances of a multi-parameter class told apart by a
-- repeated variable (generic-deriving's Uniplate' (K1 i a) a / b)
module Main (main) where

newtype K a = K a

class Kids f b where
  kids :: f -> [b]

instance {-# OVERLAPPING #-} Kids (K a) a where
  kids (K x) = [x]

instance {-# OVERLAPPABLE #-} Kids (K a) b where
  kids _ = []

main :: IO ()
main = do
  print (kids (K 'x') :: [Char])
  print (kids (K 'x') :: [Int])
