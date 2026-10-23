{-# LANGUAGE ViewPatterns #-}
module Main where
data T = Var Int | Lam T deriving Show
comp :: (T, Int) -> T
comp = fst
main :: IO ()
main = do
  let xs = [(Var 1, 10), (Lam (Var 2), 20), (Var 3, 30)]
  let cands = [ (t, i) | t@(comp -> v@Var{}) <- xs, Just i <- [Just (snd t)] ]
  print (map snd cands)
