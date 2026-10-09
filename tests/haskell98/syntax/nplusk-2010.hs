-- n+k patterns are not Haskell 2010.
fact :: Int -> Int
fact 0 = 1
fact (n+1) = (n+1) * fact n
main :: IO ()
main = print (fact 5)
