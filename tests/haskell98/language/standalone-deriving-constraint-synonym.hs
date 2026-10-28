-- A standalone deriving's declared context is the instance's, constraint
-- synonyms expanded (GHC's deriving instance DataId id => Data (HsOverLit id)).
{-# LANGUAGE TypeFamilies, StandaloneDeriving, FlexibleContexts, ConstraintKinds, UndecidableInstances #-}
data Name = Name String deriving Show
data Id = Id Int deriving Show
data PlaceHolder = PlaceHolder deriving Show

type family PostRn id ty
type instance PostRn Id ty = ty
type instance PostRn Name ty = PlaceHolder

type ShowId id = (Show id, Show (PostRn id Bool), Show (PostRn id id))

data Lit id = Lit { name :: id, ty :: PostRn id Bool, self :: PostRn id id }

deriving instance ShowId id => Show (Lit id)

main :: IO ()
main = do
  print (Lit (Id 1) True (Id 2))
  print (Lit (Name "n") PlaceHolder PlaceHolder)
