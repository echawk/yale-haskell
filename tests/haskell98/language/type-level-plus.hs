{-# LANGUAGE DataKinds, TypeOperators, TypeFamilies #-}
import GHC.TypeLits
import Data.Proxy

main :: IO ()
main = print ( natVal (Proxy :: Proxy (1 + 1))
             , natVal (Proxy :: Proxy (255 + 1))
             , natVal (Proxy :: Proxy (0 + 7))
             , natVal (Proxy :: Proxy (1000 + 24 + 3)) )
