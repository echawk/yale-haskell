{-# LANGUAGE StaticPointers #-}
import GHC.StaticPtr

inc :: Int -> Int
inc = (+ 1)

main :: IO ()
main = do
  let p = static inc :: StaticPtr (Int -> Int)
  print (deRefStaticPtr p 2)
  print (deRefStaticPtr (static (map inc)) [1, 2, 3])
