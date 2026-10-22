{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
module Main where
class Monad m => PM m where
  type PS m
  tok :: m (PS m)
instance PM IO where
  type PS IO = ()
  tok = return ()
conv :: (PM m1, PM m2, PS m1 ~ PS m2) => m1 a -> m2 a
conv _ = error "unused"
both :: (PM m1, PM m2, PS m1 ~ PS m2) => m1 () -> m2 ()
both _ = tok >> return ()
main = both (return () :: IO ()) >> putStrLn "ok"
