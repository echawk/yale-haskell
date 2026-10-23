{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
-- GRIN's representation types for a function's parameters count its
-- multi-parameter dictionaries too: x is not declared the Int that the
-- second argument's type is.
module Main where
class Conv a b where conv :: a -> b
instance Conv Int Integer where conv = toInteger
apply3 :: Conv Int b => (Int -> Int) -> Int -> Int -> b
apply3 g n m = conv (g n + m)
main = print (apply3 (* 2) 20 2 :: Integer)
