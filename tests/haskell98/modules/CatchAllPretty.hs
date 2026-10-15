-- A class with a catch-all instance (catch-all-instance.hs).
{-# LANGUAGE FlexibleInstances, UndecidableInstances #-}
module CatchAllPretty (Pretty(..)) where
class Pretty a where
  pretty :: a -> String
  prettyList :: [a] -> String
  prettyList xs = concatMap pretty xs
instance {-# OVERLAPPABLE #-} Show a => Pretty a where pretty x = "<" ++ show x ++ ">"
instance Pretty Bool where pretty b = if b then "yes" else "no"
