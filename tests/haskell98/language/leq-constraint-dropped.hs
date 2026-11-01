{-# LANGUAGE DataKinds, TypeOperators, KindSignatures, ScopedTypeVariables #-}
import GHC.TypeLits
import Data.Proxy

idx :: forall n na. (KnownNat na, KnownNat n, n <= na) => Proxy n -> Proxy na -> Integer
idx p q = natVal p + natVal q

main :: IO ()
main = print (idx (Proxy :: Proxy 2) (Proxy :: Proxy 5))
