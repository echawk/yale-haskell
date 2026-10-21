{-# LANGUAGE TypeFamilies #-}
import GHC.Exts (IsList(..))
import qualified Data.Text as T
import qualified Data.ByteString as B
main = do
  print (fromList "abc" :: T.Text)
  print (toList (B.pack [1, 2]), length (toList (T.pack "xy")))
