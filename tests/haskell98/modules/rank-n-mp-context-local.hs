{-# LANGUAGE RankNTypes #-}
module Main (main) where
import RankMPLib

idM :: Monad m => m a -> m a
idM = id

fromList :: Monad m => [a] -> m [Maybe (Chunk v a)]
fromList xs = mapM step' xs
  where
    step' x = do r <- return (Just x)
                 return $ fmap (\y -> Chunk 1 (\mv -> idM $ return (mwrite mv y))) r

main :: IO ()
main = do
  cs <- fromList "ab" :: IO [Maybe (Chunk Box Char)]
  mapM_ (\(Just c) -> print (runChunk c (MBox ()))) cs
