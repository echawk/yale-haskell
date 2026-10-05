-- Hexadecimal and octal integer literals (H98 report 2.5).
module Main where

nums :: [Int]
nums = [0x1F, 0X1f, 0xff, 0XABCDEF, 0x0, 0o17, 0O17, 0o777, 0o0, 0x10 + 0o10]

-- `0x' with no hex digit after it is 0 followed by the name x.
x :: Int
x = 5

f :: Int -> Int -> Int
f a b = a + 10 * b

pat :: Int -> String
pat 0x1F = "thirty-one"
pat 0o10 = "eight"
pat _    = "other"

result :: String
result = unwords (map show nums) ++ ("\n" ++ shows (f 0x) "\n" ++ shows (f 0o1 x) "\n"
         ++ pat 31 ++ " " ++ pat 8 ++ " " ++ pat 0 ++ "\n")

main = appendChan stdout result abort done
