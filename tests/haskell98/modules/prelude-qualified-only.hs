import qualified Prelude as P
null :: P.Int
null = 3
main :: P.IO ()
main = P.print (null, P.foldMap P.show [1 :: P.Int])
