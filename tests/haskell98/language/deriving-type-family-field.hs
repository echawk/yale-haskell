-- Derived instances over type family fields (GHC's PostRn id ty): reduced
-- where an equation matches, else a context on the application.
{-# LANGUAGE TypeFamilies, StandaloneDeriving, FlexibleContexts, UndecidableInstances #-}
data Name = Name String deriving Show
data Id = Id Int deriving Show
data PlaceHolder = PlaceHolder deriving Show

type family PostRn id ty
type instance PostRn Id ty = ty
type instance PostRn Name ty = PlaceHolder

data Lit id = Lit { val :: Int, ty :: PostRn id Bool }

deriving instance Show (PostRn id Bool) => Show (Lit id)

data Pair = Pair (PostRn Id Int) (PostRn Name Int) deriving Show

main :: IO ()
main = do
  print (Lit 3 True :: Lit Id)
  print (Lit 4 PlaceHolder :: Lit Name)
  print (Pair 1 PlaceHolder)
