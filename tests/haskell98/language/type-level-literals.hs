{-# LANGUAGE DataKinds, KindSignatures, ScopedTypeVariables #-}
import GHC.TypeLits
import Data.Proxy

newtype Tagged (s :: Symbol) = Tagged Int

label :: forall s. KnownSymbol s => Tagged s -> String
label _ = symbolVal (Proxy :: Proxy s)

main :: IO ()
main = do
  print (natVal (Proxy :: Proxy 0), natVal (Proxy :: Proxy 42), natVal (Proxy :: Proxy 1000000007))
  putStrLn (symbolVal (Proxy :: Proxy "hello, type level"))
  print (charVal (Proxy :: Proxy 'λ'))
  putStrLn (label (Tagged 1 :: Tagged "field"))
