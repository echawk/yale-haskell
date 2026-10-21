import qualified Data.String.UTF8 as U
import qualified Data.ByteString as B
main = do
  let s = U.fromString "h\233llo \8364" :: U.UTF8 B.ByteString
  print (U.toString s, U.length s, B.length (U.toRep s))
  print (U.toString (U.take 2 s), fmap fst (U.uncons s), U.foldr (:) [] (U.drop 6 s))
