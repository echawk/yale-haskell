{-# LANGUAGE TypeFamilies, TypeFamilyDependencies #-}
import Data.Kind (Type)
import Data.IORef

type family Mut (v :: Type -> Type) = (mv :: Type -> Type -> Type) | mv -> v
type family Elem c = r | r -> c

newtype Box a = Box a
newtype MBox s a = MBox (IORef a)
type instance Mut Box = MBox
type instance Elem [Int] = Bool

thaw :: Box a -> IO (Mut Box () a)
thaw (Box x) = fmap MBox (newIORef x)

flag :: Elem [Int]
flag = True

main = do
  MBox r <- thaw (Box 'q')
  readIORef r >>= print
  print flag
