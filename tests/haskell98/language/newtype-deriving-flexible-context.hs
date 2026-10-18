{-# LANGUAGE GeneralizedNewtypeDeriving #-}
-- Newtype deriving with a field headed by a type variable: the flexible
-- context Ord1 (bi a), as GHC infers it
import Data.Functor.Classes
newtype Biap bi a b = Biap (bi a b) deriving (Eq, Ord, Show, Eq1, Ord1)
newtype N f a = N (f a) deriving (Eq)
main :: IO ()
main = do
  print (liftCompare compare (Biap (1, 'a')) (Biap (1, 'b')), liftEq (==) (Biap (Right (toEnum 120)) :: Biap Either Int Char) (Biap (Left 3)) )
  print (N [1] == N [1 :: Int])
