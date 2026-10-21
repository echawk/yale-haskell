{-# LANGUAGE RankNTypes #-}
k :: (forall n. Monad n => n Int) -> Maybe Int
k m = m

g :: ((forall n. Monad n => n Int) -> Maybe Int) -> Maybe Int
g f = f (return 3)

h :: Monad m => ((forall n. Monad n => n Int) -> m Int) -> m Int
h f = f (return 4)

main :: IO ()
main = print (g k) >> h (\m -> m) >>= print
