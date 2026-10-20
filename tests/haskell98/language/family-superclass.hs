{-# LANGUAGE TypeFamilies, MultiParamTypeClasses, FlexibleContexts #-}
import Data.Kind (Type)

type family Mutable (v :: Type -> Type) :: Type -> Type

class MV mv a where
  mwrite :: mv a -> a -> String

class MV (Mutable v) a => V v a where
  vlen :: v a -> Int
  vcopy :: Mutable v a -> v a -> String
  vcopy dst src = mwrite dst (vhead src) ++ show (vlen src)
  vhead :: v a -> a

newtype Box a = Box [a]
newtype MBox a = MBox ()
type instance Mutable Box = MBox

instance Show a => MV MBox a where
  mwrite _ x = "write " ++ show x ++ "; "

instance Show a => V Box a where
  vlen (Box xs) = length xs
  vhead (Box xs) = head xs

useV :: V v a => v a -> Mutable v a -> String
useV v m = mwrite m (vhead v)

main = do
  putStrLn (vcopy (MBox ()) (Box "abc"))
  putStrLn (useV (Box [True]) (MBox ()))
