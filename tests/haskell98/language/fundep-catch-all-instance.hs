-- Functional dependency improvement and instance choice beside a
-- catch-all instance (reflection's KnownNat n => Reifies n Integer, apart by
-- kind in GHC): the more specific head at the determining positions, and
-- no improvement through the catch-all.
{-# LANGUAGE TypeFamilies, RankNTypes, FlexibleContexts, FlexibleInstances, MultiParamTypeClasses, FunctionalDependencies, UndecidableInstances #-}
module Main where
import Data.Proxy
import Data.Typeable
import GHC.TypeLits
import Control.Exception (evaluate)

class R s a | s -> a where
  refl :: proxy s -> a

data Box a = Box a
data SB w a
data St w a


instance R (SB w a) (Box b) => R (St w a) b where
  refl p = case refl (sb p) of Box a -> a

sb :: proxy (St w a) -> Proxy (SB w a)
sb _ = Proxy

withSB :: R (SB w a) (Box a) => (R (St w a) a => Proxy (St w a) -> r) -> Proxy (St w a) -> r
withSB k p = k p

main = print 1

ff :: R (SB w a) (Box a) => (forall s. R s a => Proxy s -> r) -> Proxy (St w a) -> r
ff k p = withSB k p

class Typeable b => B b where bv :: Proxy b -> Int
data B0
data B1
instance B B0 where bv _ = 0
instance B B1 where bv _ = 1
data W x y

instance (B x, B y, w ~ W x y) => R (SB w a) (Box a) where
  refl _ = undefined

rb :: Int -> (forall s. B s => Proxy s -> r) -> r
rb 0 k = k (Proxy :: Proxy B0)
rb _ k = k (Proxy :: Proxy B1)

stable :: p x -> p y -> Proxy (St (W x y) a)
stable _ _ = Proxy

rt :: Typeable a => a -> (forall s. (Typeable s, R s a) => Proxy s -> r) -> r
rt a k = rb 0 (\s0 -> rb 1 (\s1 -> withSB k $ stable s0 s1))

withSB2 :: R (SB w a) (Box a) => (R (St w a) a => Proxy (St w a) -> r) -> Proxy (St w a) -> IO r
withSB2 k p = do
  _ <- evaluate $ refl (sb p)
  evaluate $ k p

instance KnownNat n => R n Integer where
  refl p = toInteger (natVal p)
