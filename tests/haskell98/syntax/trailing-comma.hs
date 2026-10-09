module Main (
    main,
  ) where
import List (sort, nub,)
main = print (sort (nub [3, 1, 3, 2 :: Int]))
