-- GHC.Types.Unique (the ghc package): unique keys, as UniqSupply hands
-- them out (GHC/Types/Unique/Supply.hs).  KiCS2's runtime uses them.
module GHC.Types.Unique (Unique, getKey, mkUnique) where

data Unique = Unique Char Int

instance Eq Unique where
  Unique _ a == Unique _ b = a == b

instance Ord Unique where
  compare (Unique _ a) (Unique _ b) = compare a b

-- the tag, then the key (GHC writes the key in base 62)
instance Show Unique where
  show (Unique c n) = c : show n

getKey :: Unique -> Int
getKey (Unique _ n) = n

mkUnique :: Char -> Int -> Unique
mkUnique = Unique
