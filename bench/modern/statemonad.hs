-- Control.Monad.State.Strict: a pseudo-random walk run in State for
-- 2 million steps, with modify', gets and a record state.
{-# LANGUAGE BangPatterns #-}
import Control.Monad.State.Strict
import Control.Monad

data S = S { pos :: !Int, seed :: !Int, hits :: !Int }

step :: State S ()
step = do
  s <- gets seed
  let s' = (s * 1103515245 + 12345) `mod` 2147483648
      d = if (s' `div` 65536) `mod` 2 == 0 then 1 else -1
  modify' (\st -> st { seed = s', pos = pos st + d })
  p <- gets pos
  when (p == 0) $ modify' (\st -> st { hits = hits st + 1 })

loop :: Int -> State S ()
loop 0 = return ()
loop n = step >> loop (n - 1)

main :: IO ()
main = do
  let S p _ h = execState (loop 2000000) (S 0 7 0)
  print (p, h)
  print (evalState (mapM (\x -> state (\acc -> (acc + x, acc + x))) [1 .. 100000 :: Int]) 0 !! 99999)
