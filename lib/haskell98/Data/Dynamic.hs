-- Data.Dynamic (base): a value with the representation of its type
-- (Data.Typeable).
module Data.Dynamic (
    Dynamic, toDyn, fromDynamic, fromDyn, dynTypeRep, dynApply, dynApp,
    -- (base re-exports Data.Typeable: JHC's TypeRep)
    module Data.Typeable
  ) where

import Data.Typeable
import Unsafe.Coerce (unsafeCoerce)

data Obj = Obj

data Dynamic = Dynamic TypeRep Obj

instance Show Dynamic where
  showsPrec _ (Dynamic t _) = showString "<<" . shows t . showString ">>"

toDyn :: Typeable a => a -> Dynamic
toDyn x = Dynamic (typeOf x) (unsafeCoerce x)

fromDynamic :: Typeable a => Dynamic -> Maybe a
fromDynamic (Dynamic t v) = r
  where r = if t == typeOf (unJust r) then Just (unsafeCoerce v) else Nothing
        unJust :: Maybe a -> a
        unJust _ = undefined

fromDyn :: Typeable a => Dynamic -> a -> a
fromDyn d def = maybe def id (fromDynamic d)

dynTypeRep :: Dynamic -> TypeRep
dynTypeRep (Dynamic t _) = t

dynApply :: Dynamic -> Dynamic -> Maybe Dynamic
dynApply (Dynamic tf f) (Dynamic tx x) =
  case funResultTy tf tx of
    Just tr -> Just (Dynamic tr ((unsafeCoerce f :: Obj -> Obj) x))
    Nothing -> Nothing

dynApp :: Dynamic -> Dynamic -> Dynamic
dynApp f x = maybe (error "Data.Dynamic.dynApp: type error") id (dynApply f x)
