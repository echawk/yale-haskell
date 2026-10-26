-- utf8-string 1.0.2's IsString (UTF8 string), which ListLike's UTF8
-- instances expect (Agda).
{-# LANGUAGE FlexibleInstances, OverloadedStrings #-}
import Data.String.UTF8 (UTF8)
import qualified Data.String.UTF8 as U
import qualified Data.ByteString as BS
import Data.String
class IsString s => SL s where
  sl :: s -> Int
instance SL (UTF8 BS.ByteString) where
  sl = U.length
main = print (sl ("ab\955" :: UTF8 BS.ByteString))
  >> print (U.fromString "xyz" :: UTF8 BS.ByteString)
