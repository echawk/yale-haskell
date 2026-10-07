module PartialExp ( Syn, Shape(Circle), Pretty(pretty), area ) where

type Syn = Int

data Shape = Circle Syn | Square Syn

class Pretty a where
  pretty :: a -> String
  prettyList :: [a] -> String
  prettyList = concatMap pretty

instance Pretty Shape where
  pretty (Circle r) = "circle " ++ show r
  pretty (Square s) = "square " ++ show s

area :: Shape -> Syn
area (Circle r) = 3 * r * r
area (Square s) = s * s
