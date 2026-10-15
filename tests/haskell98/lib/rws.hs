-- RWST (lazy and strict), WriterT strict and the mtl classes on them.
import Control.Monad.RWS
import Control.Monad
import qualified Control.Monad.RWS.Strict as S
import qualified Control.Monad.Trans.Writer.Strict as WS
import qualified Control.Monad.Trans.RWS.Lazy as TL

step :: RWS Int [String] Int ()
step = do
  k <- ask
  n <- get
  tell ["n=" ++ show n]
  put (n + k)
  m <- asks (* 2)
  when (n < 5) (local (+ 1) step)
  modify (+ m)

stepS :: S.RWS String [Int] Int Int
stepS = do
  e <- S.ask
  S.tell [length e]
  S.modify (* 3)
  (x, w) <- S.listen (S.tell [7] >> return 4)
  S.gets (+ (x + sum w))

main :: IO ()
main = do
  print (runRWS step 1 0)
  print (S.runRWS stepS "abc" 2, evalRWS step 2 0, execRWS step 3 1)
  print (WS.runWriter (WS.tell "ab" >> WS.tell "cd" >> return 3))
  r <- TL.evalRWST (TL.ask >>= \e -> lift (print e) >> TL.tell [e] >> return (e + 1)) 5 ()
  print r
