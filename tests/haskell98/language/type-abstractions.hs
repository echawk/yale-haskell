{-# LANGUAGE TypeAbstractions, PolyKinds, DataKinds, StandaloneKindSignatures, TypeApplications, RankNTypes, LinearTypes, GADTs #-}
import Data.Kind

f :: Maybe Int -> Int
f (Just @Int n) = n
f Nothing = 0

type P :: forall k. k -> Type
data P @k (a :: k) = MkP

g :: forall {a} b. a -> b -> a
g x _ = x

data L a where
  N :: L a
  C :: a %1 -> L a %1 -> L a

len :: L a -> Int
len N = 0
len (C _ r) = 1 + len r

main :: IO ()
main = do
  print (f (Just 3), f Nothing)
  case (MkP :: P Int) of MkP -> putStrLn "ok"
  print (g @Int 'c' (3 :: Int))
  print (len (C 'a' (C 'b' N)))
