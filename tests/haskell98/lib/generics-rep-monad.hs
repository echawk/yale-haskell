{-# LANGUAGE TypeOperators #-}
import GHC.Generics
import Control.Monad (mzero, mplus)
main = do
  print (unPar1 (Par1 3 >>= \x -> Par1 (x + 1)))
  print (U1 >>= \_ -> (U1 :: U1 Int))
  let p = (Par1 1 :*: Rec1 [10, 20]) >>= \x -> (Par1 (x * 2) :*: Rec1 [x, x + 1])
  case p of Par1 a :*: Rec1 b -> print (a, b)
  print (unRec1 (Rec1 [1] `mplus` Rec1 [2 :: Int]), unM1 (M1 (Just 'a') >>= \c -> M1 (Just [c,c])) :: Maybe String)
