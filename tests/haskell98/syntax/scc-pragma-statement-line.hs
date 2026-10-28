-- An SCC pragma on a line of its own begins its statement, the expression
-- on the deeper lines after it (GHC's LlvmCodeGen).
main :: IO ()
main = do
        let xs = [1, 2, 3 :: Int]
        n <- return (sum xs)
        {-# SCC "first" #-}
          print n
        {-# SCC "second" #-} print (n * 2)
        {-# SCC "third" #-}
          mapM_
            print xs
