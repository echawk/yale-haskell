module ReexportClashC (C(..)) where
import Prelude hiding (putStr)
class C a where
  putStr :: a -> IO ()
instance C Bool where
  putStr b = print b
