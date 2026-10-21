{-# LANGUAGE GADTs, MultiParamTypeClasses, FlexibleInstances, DataKinds, KindSignatures #-}
import GHC.Generics

data Arity = Zero | One
data ToArgs res (arity :: Arity) a where
  NoToArgs :: ToArgs res 'Zero a
  To1Args :: (a -> Bool) -> (a -> res) -> ToArgs res 'One a

class Pairs enc arity f where
  pairs :: Bool -> ToArgs enc arity a -> f a -> String

instance Selector s => Pairs enc 'One (S1 s (Rec1 f)) where
  pairs b targs@(To1Args o _) m1 =
        let key = selName m1
        in key ++ "!"
main :: IO ()
main = putStrLn "ok"
