-- Standalone deriving with a declared context on an associated type's
-- application (megaparsec's ParseError s e, Show (Token s)): the
-- declared context is the instance's, as GHC takes it.
{-# LANGUAGE TypeFamilies, StandaloneDeriving, FlexibleContexts, UndecidableInstances, DeriveDataTypeable #-}
import Data.Data
class Stream s where
  type Token s
instance Stream [a] where
  type Token [a] = a
data PE s e = TE Int (Maybe (Token s)) | FE e
deriving instance (Show (Token s), Show e) => Show (PE s e)
deriving instance (Eq (Token s), Eq e) => Eq (PE s e)
deriving instance (Data s, Data (Token s), Data e) => Data (PE s e)
main = do
  print (TE 1 (Just 'c') :: PE String ())
  print (TE 1 Nothing == (TE 1 Nothing :: PE String ()), FE () == (TE 2 Nothing :: PE String ()))
  print (toConstr (FE () :: PE String ()))
