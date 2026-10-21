{-# LANGUAGE DeriveGeneric, TypeOperators, FlexibleContexts, DefaultSignatures #-}
module Main (main) where
import GHC.Generics

data Color = Red | Green | Blue deriving (Show, Generic)
data P a = P { px :: a, py :: Int } | Q a deriving (Show, Generic, Generic1)
newtype W f a = W (f [a]) deriving (Generic1)

class GCount f where
  gcount :: f p -> Int
instance GCount U1 where gcount _ = 0
instance GCount (K1 i c) where gcount _ = 1
instance (GCount f, GCount g) => GCount (f :*: g) where
  gcount (a :*: b) = gcount a + gcount b
instance (GCount f, GCount g) => GCount (f :+: g) where
  gcount (L1 a) = gcount a
  gcount (R1 b) = gcount b
instance GCount f => GCount (M1 i c f) where gcount (M1 x) = gcount x

class GNames f where
  gnames :: f p -> [String]
instance GNames U1 where gnames _ = []
instance (GNames f, GNames g) => GNames (f :*: g) where
  gnames (a :*: b) = gnames a ++ gnames b
instance (GNames f, GNames g) => GNames (f :+: g) where
  gnames (L1 a) = gnames a
  gnames (R1 b) = gnames b
instance (Constructor c, GNames f) => GNames (M1 C c f) where
  gnames m@(M1 x) = conName m : gnames x
instance GNames f => GNames (M1 D d f) where
  gnames (M1 x) = gnames x
instance Datatype d => GNames' (M1 D d f) where
  dname m = datatypeName m ++ "/" ++ moduleName m
instance Selector s => GNames (M1 S s f) where
  gnames m = [selName m]
class GNames' f where
  dname :: f p -> String

count :: (Generic a, GCount (Rep a)) => a -> Int
count = gcount . from

names :: (Generic a, GNames (Rep a)) => a -> [String]
names = gnames . from

main :: IO ()
main = do
  print (map count [Red, Green, Blue], count (P 'x' 3), count (Q 'y'))
  print (names Blue, names (P True 1), names (Q ()))
  putStrLn (dname (from Green))
  print (to (from (P "a" 2)) :: P String, to (from Green) :: Color)
  print (to1 (fmap succ (from1 (P 'a' 5))) :: P Char)
  case to1 (fmap (+1) (from1 (W (Just [1, 2 :: Int])))) of W m -> print m
