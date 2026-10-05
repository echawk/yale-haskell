-- A module with no header is `module Main(main) where' (H98 report 5.1).
-- Besides main it may define any other names.

helper :: Int -> Int
helper n = n * 6

data Colour = Red | Green

name :: Colour -> String
name Red = "red"
name Green = "green"

result :: String
result = show (helper 7) ++ " " ++ name Green ++ "\n"

main = appendChan stdout result abort done
