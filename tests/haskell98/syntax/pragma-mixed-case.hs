data P = P {-# UNPACk #-} !Int {-# Unpack #-} !Bool
  deriving Show
{-# Noinline f #-}
f :: Int -> Int
f = (+ 1)
main = print (P (f 1) True)
