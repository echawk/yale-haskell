-- A local signature mentioning the enclosing binding's scoped variable
-- keeps its rank-2 arguments polymorphic (Agda's metasCreatedBy).
{-# LANGUAGE RankNTypes, ScopedTypeVariables, BangPatterns #-}
module Main where

import Data.Functor.Const
import qualified Data.Map as MapS

type Lens' o i = forall f. Functor f => (i -> f i) -> o -> f o

data St = St { _open :: MapS.Map Int String, _solved :: MapS.Map Int String }

stOpen :: Lens' St (MapS.Map Int String)
stOpen f s = fmap (\x -> s { _open = x }) (f (_open s))

stSolved :: Lens' St (MapS.Map Int String)
stSolved f s = fmap (\x -> s { _solved = x }) (f (_solved s))

class Monad m => ReadSt m where getSt :: m St
instance ReadSt IO where getSt = return (St (MapS.fromList [(1,"a"),(5,"b")]) (MapS.fromList [(7,"c")]))

useTC :: ReadSt m => Lens' St a -> m a
useTC l = getConst . l Const <$> getSt

createdBy :: forall m a. ReadSt m => m a -> m (a, MapS.Map Int String, MapS.Map Int String)
createdBy m = do
  a  <- m
  os <- created stOpen 2
  ss <- created stSolved 2
  return (a, os, ss)
  where
  created :: Lens' St (MapS.Map Int String) -> Int -> m (MapS.Map Int String)
  created store next = do
    ms <- useTC store
    return $ case MapS.splitLookup next ms of
      (_, _, ms') -> ms'

main :: IO ()
main = createdBy (return ()) >>= print
