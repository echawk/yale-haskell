-- Operator symbols are lexed by maximal munch (Haskell 98 section
-- 2.4): <->, |-|, =>>, @@, ~~ and ::: are ordinary operators even
-- though they start with a reserved operator (<-, |, =>, @, ~, ::).
module Main where
import Dialogue (stdout, appendChan, done, abort)

infixl 6 <->, |-|
infixr 5 :::

data L = Nil | Int ::: L

(<->), (|-|), (=>>), (@@), (~~) :: Int -> Int -> Int
a <-> b = a - b
a |-| b = abs (a - b)
a =>> b = a * b
a @@ b  = a + b
a ~~ b  = max a b

total :: L -> Int
total Nil       = 0
total (x ::: r) = x + total r

out :: String
out = unlines [ show (10 <-> 3, 3 |-| 10, 6 =>> 7, 1 @@ 2, 4 ~~ 9)
              , show (total (1 ::: 2 ::: 3 ::: Nil)) ]

main = appendChan stdout out abort done
