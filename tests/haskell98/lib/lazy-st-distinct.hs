import qualified Control.Monad.ST as S
import qualified Control.Monad.ST.Lazy as L
import Data.STRef

class Name m where name :: m () -> String
instance Name (S.ST s) where name _ = "strict"
instance Name (L.ST s) where name _ = "lazy"

sumST :: [Int] -> S.ST s Int
sumST xs = do { r <- newSTRef 0; mapM_ (\x -> modifySTRef r (+x)) xs; readSTRef r }

main = do
  print (S.runST (sumST [1..10]), L.runST (L.strictToLazyST (sumST [1..4]) >>= \n -> return (n * 2)))
  putStrLn (name (return () :: S.ST s ()) ++ " " ++ name (return () :: L.ST s ()))
