import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C
main = print (B.unpack (B.sort (B.pack [3,1,2])), C.sort (C.pack "cab"), B.foldr' (+) 0 (B.pack [1,2]))
