-- A pattern signature that disagrees with the pattern's type is an error.
f :: Int -> Int
f (x :: Bool) = 1
main :: IO ()
main = print (f 1)
