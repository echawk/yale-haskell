{-# LANGUAGE TypeFamilies, ParallelListComp #-}
-- A let in a case on a family-typed scrutinee whose type an improvement
-- decides later (lm <- asks rEMap; case mlookup a lm of Just (_, as) -> let
-- ss = [a =* v | a <- as | v <- vs]: JHC's FromGrin2): not generalized.
module Main where
import qualified Data.Map as M
import Control.Monad.Reader

type family Key m
type family Value m
type instance Key (M.Map k v) = k
type instance Value (M.Map k v) = v
class MapLike m where mlookup :: Key m -> m -> Maybe (Value m)
instance Ord k => MapLike (M.Map k v) where mlookup = M.lookup

class TE a where te :: a -> String
instance TE Int where te = show
instance TE Bool where te = show
(=*) :: (TE x, TE y) => x -> y -> String
x =* y = te x ++ "=" ++ te y

data Env = Env { rEMap :: M.Map Char (String, [Int]) }

conv :: Char -> [Bool] -> Reader Env [String]
conv a vs = do
  lm <- asks rEMap
  case a `mlookup` lm of
    Just (nm, as) -> do
      let ss = [ a =* v | a <- as | v <- vs ]
      return (concat ss : [nm])
    Nothing -> return []

main = print (runReader (conv 'x' [True]) (Env (M.fromList [('x', ("n", [7]))])))
