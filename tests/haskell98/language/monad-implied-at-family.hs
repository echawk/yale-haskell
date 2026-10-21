{-# LANGUAGE GADTs, TypeFamilies, FlexibleContexts #-}
import Data.Kind (Type)
class Rp p where
  type Rep p :: Type -> Type
  tab :: (d -> Rep p c) -> p d c
  sv :: p d c -> d -> Rep p c

newtype Fn a b = Fn (a -> Maybe b)
instance Rp Fn where
  type Rep Fn = Maybe
  tab = Fn
  sv (Fn f) = f

data Prep p a where
  Prep :: x -> p x a -> Prep p a

instance (Applicative (Rep p), Rp p) => Functor (Prep p) where
  fmap f (Prep x p) = Prep x (tab (fmap f . sv p))
instance (Applicative (Rep p), Rp p) => Applicative (Prep p) where
  pure a = Prep () $ tab $ const $ pure a
  Prep xf pf <*> Prep xa pa = Prep (xf, xa) (tab go) where
    go (xf', xa') = sv pf xf' <*> sv pa xa'

instance (Monad (Rep p), Rp p) => Monad (Prep p) where
  Prep xa pa >>= f = Prep xa $ tab $ \x -> sv pa x >>= \a -> case f a of
    Prep xb pb -> sv pb xb

run :: Prep Fn a -> Maybe a
run (Prep x p) = sv p x

main :: IO ()
main = print (run ((+) <$> pure 1 <*> pure (2 :: Int)), run (pure 5 >>= \x -> pure (x * 2 :: Int)))
