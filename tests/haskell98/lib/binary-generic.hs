-- binary's Generic put and get (GHC's ghc-boot: Binary Extension):
-- the same bytes as GHC's binary
{-# LANGUAGE DeriveGeneric, DeriveAnyClass #-}
import Data.Binary
import GHC.Generics
import qualified Data.ByteString.Lazy as L

data Color = Red | Green | Blue | Other Int deriving (Show, Generic)
instance Binary Color
data P = P Int Bool [Color] deriving (Show, Generic)
instance Binary P

main = do
  print (L.unpack (encode [Red, Green, Blue, Other 7]))
  print (decode (encode (P 3 True [Blue, Other 2])) :: P)
