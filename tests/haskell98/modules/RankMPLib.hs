{-# LANGUAGE TypeFamilies, MultiParamTypeClasses, FlexibleContexts, RankNTypes, FlexibleInstances #-}
module RankMPLib where
import Data.Kind (Type)

type family Mutable (v :: Type -> Type) :: Type -> Type

class MV mv a where
  mwrite :: mv a -> a -> String

class MV (Mutable v) a => V v a where
  vhead :: v a -> a

newtype Box a = Box [a]
newtype MBox a = MBox ()
type instance Mutable Box = MBox

instance Show a => MV MBox a where
  mwrite _ x = "write " ++ show x

instance Show a => V Box a where
  vhead (Box xs) = head xs

-- a rank-2 field whose context has a multi-parameter class
data Chunk v a = Chunk Int (forall m. (Monad m, V v a) => Mutable v a -> m String)

single :: a -> Chunk v a
single x = Chunk 1 (\mv -> return (mwrite mv x))

runChunk :: V v a => Chunk v a -> Mutable v a -> [String]
runChunk (Chunk n f) mv = replicate n "" ++ f mv
