import Control.Applicative

main :: IO ()
main = do
  print (pure 3 :: (String, Int))
  print (("a", (+ 1)) <*> ("b", 2 :: Int))
  print (("x", 1 :: Int) >>= \n -> ("y", n * 2))
