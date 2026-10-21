-- GHC.Compact (ghc-compact): compact regions, which here are the value
-- itself (Yale Haskell has no compact heap); getCompact gives it back.
module GHC.Compact (
    Compact, compact, compactWithSharing, compactAdd, compactAddWithSharing,
    compactSized, getCompact, inCompact, isCompact, compactSize
  ) where


import Data.Word (Word)

newtype Compact a = Compact a

compact, compactWithSharing :: a -> IO (Compact a)
compact x = return (Compact x)
compactWithSharing = compact

compactSized :: Int -> Bool -> a -> IO (Compact a)
compactSized _ _ = compact

compactAdd, compactAddWithSharing :: Compact b -> a -> IO (Compact a)
compactAdd _ = compact
compactAddWithSharing = compactAdd

getCompact :: Compact a -> a
getCompact (Compact x) = x

inCompact :: Compact b -> a -> IO Bool
inCompact _ _ = return False

isCompact :: a -> IO Bool
isCompact _ = return False

compactSize :: Compact a -> IO Word
compactSize _ = return 0
