module NewtypeViaContextA where
class PartialOrd a where leq :: a -> a -> Bool
newtype Favorites a = Favorites [a] deriving Show
instance PartialOrd a => Semigroup (Favorites a) where
  Favorites a <> Favorites b = Favorites (filter (\x -> any (leq x) b) a ++ b)
instance PartialOrd a => Monoid (Favorites a) where
  mempty = Favorites []
