-- base's withKnownNat (an SNat as KnownNat's dictionary) and an
-- argument whose type has a context on an outer variable (KnownNat n =>
-- r): its dictionary given inside the argument, at a variable or a type.
{-# LANGUAGE RankNTypes, ScopedTypeVariables, DataKinds #-}
module Main where
import GHC.TypeNats
import Data.Proxy

f :: forall n. KnownNat n => Proxy n -> Natural
f p = natVal p + 1

g :: forall r. Natural -> (forall n. KnownNat n => Proxy n -> r) -> r
g m k = withSomeSNat m (\(sn :: SNat n) -> withKnownNat sn (k (Proxy :: Proxy n)))

h :: SNat n -> Natural
h sn = withKnownNat sn (natVal sn)

main = do
  print (natVal (Proxy :: Proxy 7))
  print (h (natSing :: SNat 5))
  print (g 41 f)
