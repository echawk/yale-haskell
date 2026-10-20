{-# LANGUAGE BangPatterns, ExistentialQuantification #-}
module Main (main) where
import GHC.Exts (SPEC(..))

data Step s a = Yield a s | Skip s | Done
data Stream m a = forall s. Stream (s -> m (Step s a)) s

cmpBy :: (Monad m) => (a -> b -> Ordering) -> Stream m a -> Stream m b -> m Ordering
{-# INLINE cmpBy #-}
cmpBy cmp (Stream step1 t1) (Stream step2 t2) = cmp_loop0 SPEC t1 t2
  where
    cmp_loop0 !_ s1 s2 = do
      r <- step1 s1
      case r of
        Yield x s1' -> cmp_loop1 SPEC x s1' s2
        Skip    s1' -> cmp_loop0 SPEC   s1' s2
        Done        -> cmp_null s2
    cmp_loop1 !_ x s1 s2 = do
      r <- step2 s2
      case r of
        Yield y s2' -> case x `cmp` y of
                         EQ -> cmp_loop0 SPEC s1 s2'
                         c  -> return c
        Skip    s2' -> cmp_loop1 SPEC x s1 s2'
        Done        -> return GT
    cmp_null s2 = do
      r <- step2 s2
      case r of
        Yield _ _ -> return LT
        Skip s2'  -> cmp_null s2'
        Done      -> return EQ

fromList :: Monad m => [a] -> Stream m a
fromList xs = Stream (\l -> return (case l of { (y:ys) -> Yield y ys; [] -> Done })) xs

cmpIO :: [Int] -> [Int] -> IO Ordering
cmpIO a b = cmpBy compare (fromList a) (fromList b)

main :: IO ()
main = cmpIO [1,2,3] [1,2,4] >>= print
