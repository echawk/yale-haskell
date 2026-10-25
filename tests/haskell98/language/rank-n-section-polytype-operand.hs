-- A section that leaves out an operator's polytype argument, bound
-- without a signature and given lenses: Agda's insertMetaVar.
{-# LANGUAGE RankNTypes #-}
module Main where
import Data.Functor.Identity
import Control.Monad.State

type Lens' o i = forall f. Functor f => (i -> f i) -> o -> f o

over :: Lens' o i -> (i -> i) -> o -> o
over l f o = runIdentity $ l (Identity . f) o

(<&>) :: Functor f => f a -> (a -> b) -> f b
x <&> f = fmap f x

data St = St { stA :: [Int], stB :: [Int] } deriving Show

lensA :: Lens' St [Int]
lensA f s = f (stA s) <&> \ x -> s { stA = x }

lensB :: Lens' St [Int]
lensB f s = f (stB s) <&> \ x -> s { stB = x }

modifyL :: MonadState St m => Lens' St a -> (a -> a) -> m ()
modifyL l = modify . over l

ins :: Int -> State St ()
ins n
  | even n    = insert lensA
  | otherwise = insert lensB
  where
  insert = (`modifyL` (n :))

main :: IO ()
main = print (execState (mapM_ ins [1..5]) (St [] []))
