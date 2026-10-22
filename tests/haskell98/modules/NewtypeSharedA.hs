{-# LANGUAGE DefaultSignatures #-}
module NewtypeSharedA where
class Null a where
  empty :: a
  null  :: a -> Bool


instance Null [a] where
  empty = []
  null = Prelude.null
