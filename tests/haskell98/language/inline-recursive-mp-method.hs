{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
-- An INLINE method of a multi-parameter instance that calls itself at
-- its own instance through the dictionary (indexed-traversable's
-- FunctorWithIndex [Int] Tree) is a loop breaker, not inlined forever.
data Rose a = Rose a [Rose a]

instance Functor Rose where
  fmap f (Rose a rs) = Rose (f a) (map (fmap f) rs)

class Functor f => IMap i f | f -> i where
  imap :: (i -> a -> b) -> f a -> f b

instance IMap Int [] where
  imap f = go 0 where
    go _ []     = []
    go n (x:xs) = f n x : go (n + 1) xs
  {-# INLINE imap #-}

instance IMap [Int] Rose where
  imap f (Rose a as) = Rose (f [] a) $ imap (\i -> imap (f . (:) i)) as
  {-# INLINE imap #-}

total :: Rose Int -> Int
total (Rose a rs) = a + sum (map total rs)

main :: IO ()
main = print (total (imap (\is x -> x + sum is) (Rose 1 [Rose 2 [Rose 3 []], Rose 4 []])))
