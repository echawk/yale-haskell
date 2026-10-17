-- liftA2 as an Applicative method, Bifunctor Const and triples,
-- Coercible, Text.Read's Read.
import Data.Bifunctor
import Data.Functor.Const
import Data.Coerce
import Text.Read (Read(..), readMaybe)
import Control.Applicative

newtype Age = Age Int deriving Show
newtype P a = P (Maybe a) deriving Show
instance Functor P where fmap f (P m) = P (fmap f m)
instance Applicative P where
  pure = P . Just
  liftA2 f (P a) (P b) = P (liftA2 f a b)

toInts :: Coercible a Int => [a] -> [Int]
toInts = map coerce

main = do
  print (getConst (first (+1) (Const 1 :: Const Int String)))
  print (bimap show not ((), 1 :: Int, True))
  print (toInts [Age 3])
  print (P (Just (+1)) <*> P (Just 2), (,) <$> P (Just 'a') <*> pure 'b')
  print (readMaybe "12" :: Maybe Int, readsPrec 0 "7" :: [(Int, String)])
