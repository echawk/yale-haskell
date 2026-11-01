-- GHC.StaticPtr (base), without the static pointer table: with
-- StaticPointers, `static e` is fromStaticPtr (mkStaticPtr e)
-- (parser/exp-parser.mumble).  deRefStaticPtr works; there are no keys.
module GHC.StaticPtr (StaticPtr, deRefStaticPtr, IsStatic(fromStaticPtr), mkStaticPtr) where

newtype StaticPtr a = StaticPtr a

deRefStaticPtr :: StaticPtr a -> a
deRefStaticPtr (StaticPtr a) = a

mkStaticPtr :: a -> StaticPtr a
mkStaticPtr = StaticPtr

class IsStatic p where
  fromStaticPtr :: StaticPtr a -> p a

instance IsStatic StaticPtr where
  fromStaticPtr = id
