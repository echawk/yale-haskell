{-# LANGUAGE TemplateHaskell #-}
module QuoteGen where
import Language.Haskell.TH

-- the TH paper's power: unrolled at compile time
power :: Int -> Q Exp
power 0 = [| const 1 |]
power n = [| \x -> x * $(power (n - 1)) x |]

-- the paper's printf
data Format = D | S | L String

parse :: String -> [Format]
parse "" = []
parse ('%' : 'd' : cs) = D : parse cs
parse ('%' : 's' : cs) = S : parse cs
parse cs = L lit : parse rest where (lit, rest) = break (== '%') cs

gen :: [Format] -> Q Exp -> Q Exp
gen [] acc = acc
gen (D : xs) acc = [| \n -> $(gen xs [| $acc ++ show (n :: Int) |]) |]
gen (S : xs) acc = [| \s -> $(gen xs [| $acc ++ s |]) |]
gen (L s : xs) acc = gen xs [| $acc ++ s |]

printf :: String -> Q Exp
printf fmt = gen (parse fmt) [| "" |]

-- the scoping example: x stays this module's x, y is lifted
x :: Int
x = 10
g :: Int -> Q Exp
g y = [| x + y |]

-- sel i n
sel :: Int -> Int -> Q Exp
sel i n = do
  vs <- mapM (\k -> newName ("v" ++ show k)) [1 .. n]
  lamE [tupP (map varP vs)] (varE (vs !! (i - 1)))
