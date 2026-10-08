-- Unknown calls (generic apply): exact, partial and over-saturated
-- applications, arities above 4, and constructors as function values.

data P = P !Int Int deriving Show
data T = A | B Int Int Int deriving Show

f3 :: Int -> Int -> Int -> Int
f3 a b c = a * 100 + b * 10 + c

f6 :: Int -> Int -> Int -> Int -> Int -> Int -> Int
f6 a b c d e g = a + b + c + d + e + g

-- returns a function: calls with more arguments than its arity
pick :: Bool -> (Int -> Int -> Int)
pick True  = (+)
pick False = (-)

app1 :: (a -> b) -> a -> b
app1 g x = g x

app2 :: (a -> b -> c) -> a -> b -> c
app2 g x y = g x y

app5 :: (a -> a -> a -> a -> a -> b) -> a -> b
app5 g x = g x x x x x

main :: IO ()
main = do
  print (map (f3 1 2) [3, 4])               -- PAP of 2 arguments
  print (zipWith (f3 4) [5, 6] [7, 8])      -- PAP applied to 2
  print (app1 (app1 (f3 1) 2) 3)            -- PAP of a PAP
  print (app2 pick True 3 `seq` app2 (pick False) 9 4)
  print (foldr (\g acc -> g acc) 0 [(+ 1), (* 2), subtract 3])
  print (app5 (f6 1) 2)                     -- 6 arguments: apply-n
  print (map (uncurry P) [(1, 2), (3, 4)])  -- constructor values
  print (zipWith3 B [1, 2] [3, 4] [5, 6], A)
  print (map ($ 10) (map f3 [1, 2] `ap` [3]))

ap :: [a -> b] -> [a] -> [b]
ap gs xs = [g x | g <- gs, x <- xs]
