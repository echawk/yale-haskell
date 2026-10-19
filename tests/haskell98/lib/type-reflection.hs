-- Type.Reflection, Data.Type.Coercion and GHC.TypeLits' names.
{-# LANGUAGE DataKinds, KindSignatures #-}
import qualified Type.Reflection as R
import Data.Type.Coercion
import GHC.TypeLits
import GHC.TypeNats (SNat)
import Data.Proxy
data Three
instance KnownSymbol Three where symbolSing = undefined
main = do
  print (R.typeRep :: R.TypeRep [Int])
  print (R.typeOf 'x', R.eqTypeRep (R.typeRep :: R.TypeRep Int) (R.typeRep :: R.TypeRep Int) /= Nothing)
  print (coerceWith (Coercion :: Coercion Int Int) 5)
