-- A foreign export whose type cannot cross to C is a compile error.
module Main where
foreign export ccall "sh" sh :: String -> Int
sh = length
main = print 1
