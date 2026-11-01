{-# LANGUAGE UnboxedSums, UnboxedTuples #-}
f :: Int -> (# Int | Bool | String #)
f 0 = (# | True | #)
f 1 = (# | | "s" #)
f n = (# n | | #)
g :: (# Int | Bool | String #) -> String
g (# n | | #) = show n
g (# | b | #) = show b
g (# | | s #) = s
h :: (# Int, Int #) -> Int
h (# a, b #) = a + b
main = mapM_ (\n -> putStrLn (g (f n))) [0, 1, 5] >> print (h (# 1, 2 #))
