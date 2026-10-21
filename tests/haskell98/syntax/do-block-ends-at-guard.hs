-- A do block that is a guard's right-hand side ends at the next guard's |
-- in its statements' column (the layout rule's parse-error(t))
module Main (main) where

main :: IO ()
main = do
    let go i | i < 3 = do
            print i
            go (i + 1)
            | otherwise = return ()
    go (0 :: Int)
