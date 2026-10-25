-- An instance of Hashable without methods hashes the type's Generic
-- representation (hashable's default; Agda's instance Hashable LibName).
{-# LANGUAGE DeriveGeneric #-}
import GHC.Generics (Generic)
import Data.Hashable
data L = L String [Int] | M deriving (Eq, Generic)
instance Hashable L
main :: IO ()
main = do
  print (hash (L "a" [1]) == hash (L "a" [1]))
  print (hash (L "a" [1]) /= hash (L "a" [2]), hash M /= hash (L "" []))
