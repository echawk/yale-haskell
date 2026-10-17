-- Type synonyms for polytypes (microlens's Lens and Traversal): a
-- signature naming one means the polytype.
{-# LANGUAGE RankNTypes #-}
import Data.Functor.Identity
import Data.Functor.Const

type Lens s t a b = forall f. Functor f => (a -> f b) -> s -> f t
type Lens' s a = Lens s s a a
type Traversal s t a b = forall f. Applicative f => (a -> f b) -> s -> f t

_1 :: Lens (a, c) (b, c) a b
_1 f (a, c) = (\b -> (b, c)) <$> f a

both :: Traversal (a, a) (b, b) a b
both f (a, b) = (,) <$> f a <*> f b

over :: ((a -> Identity b) -> s -> Identity t) -> (a -> b) -> s -> t
over l f = runIdentity . l (Identity . f)

view :: ((a -> Const a a) -> s -> Const a s) -> s -> a
view l = getConst . l Const

second :: Lens' (a, a) a
second f (x, y) = (\b -> (x, b)) <$> f y

main = do
  print (view second ("a", "b"))
  print (view _1 (1 :: Int, "x"))
  print (over _1 (+1) (1 :: Int, "x"))
  print (over both show (1 :: Int, 2))
