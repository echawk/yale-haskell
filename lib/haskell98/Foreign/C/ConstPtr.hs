-- Foreign.C.ConstPtr (base): a pointer to const data, for foreign imports.
module Foreign.C.ConstPtr (ConstPtr(ConstPtr, unConstPtr)) where

import Foreign.Ptr (Ptr)

newtype ConstPtr a = ConstPtr { unConstPtr :: Ptr a } deriving (Eq, Ord)

instance Show (ConstPtr a) where
  showsPrec d (ConstPtr p) = showParen (d > 10) (showString "ConstPtr " . showsPrec 11 p)
