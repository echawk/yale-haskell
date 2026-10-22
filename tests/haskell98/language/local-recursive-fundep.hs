{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
-- A local recursive binding whose fundep improvement (Singleton a1
-- (NonEmpty a2)) unifies its overloaded variables before generalization
module Main (main) where
import Data.List.NonEmpty (NonEmpty(..), (<|))
import qualified Data.List.NonEmpty as NE

class Singleton el coll | coll -> el where
  singleton :: el -> coll
instance Singleton a (NonEmpty a) where
  singleton x = x :| []

class IsExpr e where
  wrap :: String -> e
  name :: e -> Maybe String

instance IsExpr [Char] where
  wrap = id
  name s = if null s then Nothing else Just s

data P e = Hole | NoP e deriving Show

parse :: IsExpr e => [e] -> [P e]
parse es = concatMap (NE.toList . splitExpr) es
  where
  splitExpr :: IsExpr e => e -> NonEmpty (P e)
  splitExpr e = case name e of
    Just n -> splitName n
    _      -> noSplit
    where
    noSplit = singleton (NoP e)
    splitName n = splitParts (NE.fromList (words n))
      where
      splitParts (s :| []) = singleton (part s)
      splitParts (s :| t : ss) = part s <| splitParts (t :| ss)
      part s = NoP (wrap s)

main :: IO ()
main = print (parse ["a b", ""])
