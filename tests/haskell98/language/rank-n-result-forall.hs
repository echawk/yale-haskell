{-# LANGUAGE RankNTypes #-}
-- A forall in an arrow's result floats to the top, as in GHC
k :: Int -> (forall a. Show a => a -> String)
k n = \x -> show n ++ show x

k2 :: Int -> forall a. Show a => a -> String
k2 n x = show n ++ show x

main :: IO ()
main = putStrLn (k 1 True ++ k2 2 'c')
