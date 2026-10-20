module Main (main) where
import RankMPLib
main :: IO ()
main = do
  print (runChunk (single 'z' :: Chunk Box Char) (MBox ()))
  case single (3 :: Int) :: Chunk Box Int of
    Chunk _ f -> f (MBox ()) >>= putStrLn
