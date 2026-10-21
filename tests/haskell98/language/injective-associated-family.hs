{-# LANGUAGE TypeFamilies, TypeFamilyDependencies #-}
import Data.List.NonEmpty (NonEmpty(..))
class HasNE s where
  type NE s = t | t -> s
  ne :: s -> Maybe (NE s)
instance HasNE [a] where
  type NE [a] = NonEmpty a
  ne [] = Nothing
  ne (x : xs) = Just (x :| xs)
main :: IO ()
main = print (ne "ab", ne "")
