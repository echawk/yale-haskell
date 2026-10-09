import Foreign
foreign import ccall "abs" bad :: [Int] -> Int
foreign import ccall "abs" bad2 :: Num a => a -> a
main = print 1
