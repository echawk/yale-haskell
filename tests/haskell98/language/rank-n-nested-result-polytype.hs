{-# LANGUAGE RankNTypes #-}
module Main where
class Sh a where sh :: a -> String
instance Sh Int where sh = show
instance Sh Bool where sh = show
type Q r = forall a. Sh a => a -> r
both :: Q (Q String) -> Int -> Bool -> String
both f x y = f x y ++ "/" ++ f y x
pair :: (Sh a, Sh b) => a -> b -> String
pair a b = sh a ++ "," ++ sh b
main = putStrLn (both (\a -> pair a) 1 True)
