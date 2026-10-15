-- Catch-all instances (UndecidableInstances): instance Show a => Pretty a
-- from another module, overridden by specific instances, used by a
-- default method and through a polymorphic function.
{-# LANGUAGE FlexibleInstances, UndecidableInstances #-}
import CatchAllPretty
data Color = Red | Green deriving Show
instance Pretty Char where pretty c = [c]
both :: (Pretty a, Pretty b) => a -> b -> String
both a b = pretty a ++ "," ++ pretty b
main = do
  putStrLn (pretty (3 :: Int) ++ pretty True ++ pretty Red ++ pretty 'x')
  putStrLn (pretty [Just 1, Nothing] ++ pretty (1.5 :: Double, "s"))
  putStrLn (both Green False)
  putStrLn (prettyList [1, 2, 3 :: Int] ++ prettyList "abc")
