{-# LANGUAGE Haskell98 #-}
{-# OPTIONS -Wall #-}
-- H98 pragmas (report 11): INLINE, NOINLINE and SPECIALIZE are
-- accepted; unknown pragmas are ignored like comments.  Yale's own
-- annotations ({-# f :: Inline #-}, {-#STRICT#-}) keep working.
module Main where
import Dialogue (stdout, appendChan, done, abort)

{-# INLINE square #-}
square :: Int -> Int
square x = x * x

{-# NOINLINE cube #-}
cube :: Int -> Int
cube x = x * square x

{-# SPECIALIZE sumSquares :: [Int] -> Int #-}
{-# SPECIALISE sumSquares :: [Integer] -> Integer #-}
sumSquares :: Num a => [a] -> a
sumSquares xs = sum [ x * x | x <- xs ]

{-# INLINE twice #-}
{-# INLINE thrice #-}
twice, thrice :: (a -> a) -> a -> a
twice f = f . f
thrice f = f . f . f

{-# NOT_A_REAL_PRAGMA with arbitrary
    contents spanning lines #-}

-- Yale's annotation syntax
{-# addOne :: Inline #-}
addOne :: Int -> Int
addOne = (+ 1)

data P = P Int {-#STRICT#-} Int

pfst :: P -> Int
pfst (P a _) = a

local :: Int -> Int
local n = go n + go (n + 1)
  where {-# INLINE go #-}
        go k = k * 10

class Size a where
  {-# INLINE size #-}
  size :: a -> Int
  size _ = 0

instance Size Bool where
  {-# INLINE size #-}
  size _ = 1

instance Size Char where
  {-# SPECIALIZE instance Size Char #-}
  size _ = 2

result :: String
result = unlines
  [ show (square 7)
  , show (cube 3)
  , show (sumSquares [1, 2, 3 :: Int])
  , show (sumSquares [4, 5 :: Integer])
  , show (twice addOne 0) ++ " " ++ show (thrice addOne 0)
  , show (pfst (P 42 0))
  , show (local 2)
  , show (size True + size 'c')
  ]

main = appendChan stdout result abort done
