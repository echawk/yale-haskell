-- Fixity declarations in let, where and class bodies, and anywhere among
-- the topdecls (H98 report 4.4.2).
module Main where
import Dialogue (stdout, appendChan, done, abort)

-- where: <+> is right associative, so 100 <+> 10 <+> 1 = 100 - (10 - 1)
whereFix :: Int
whereFix = 100 <+> 10 <+> 1
  where
    infixr 5 <+>
    a <+> b = a - b

-- let: |> binds tighter than +, and the backquoted `minus` is left
-- associative at precedence 7.
letFix :: Int
letFix =
  let infixl 7 |>
      infixl 7 `minus`
      x |> y = x * 10 + y
      minus = (-)
  in  1 + 2 |> 3 + (20 `minus` 5 `minus` 3)

-- A local fixity shadows the top-level one for the local operator only.
infixl 6 &
(&) :: Int -> Int -> Int
a & b = a - b

shadow :: (Int, Int)
shadow = (10 & 4 & 3, inner)
  where
    inner = 10 & 4 & 3
      where
        infixr 6 &
        x & y = x - y

-- Class body fixity for a method.
class Combine a where
  infixr 4 <->
  (<->) :: a -> a -> a

instance Combine Int where
  a <-> b = a - b

classFix :: Int
classFix = 10 <-> 4 <-> 3

-- A top-level fixity after other declarations.
infixr 3 ^^^
(^^^) :: Int -> Int -> Int
a ^^^ b = a * 2 + b

topFix :: Int
topFix = 1 ^^^ 2 ^^^ 3

result :: String
result = unlines
  [ show whereFix
  , show letFix
  , show (fst shadow) ++ " " ++ show (snd shadow)
  , show classFix
  , show topFix
  ]

main = appendChan stdout result abort done
