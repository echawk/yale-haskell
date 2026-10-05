-- Strictness flags on constructor fields (H98 report 4.2.1).
module Main where

data T = T !Int Int

data Cx = !Int :* !Int

data Pt a = Pt !a !(Maybe' a) [a]

data Maybe' a = None | Some a

data Mixed = Mixed Int {-#STRICT#-} !Int

tsum :: T -> Int
tsum (T a b) = a + b

tfst :: T -> Int
tfst (T a _) = a

mag :: Cx -> Int
mag (a :* b) = a * a + b * b

ptsum :: Pt Int -> Int
ptsum (Pt x None ys) = x + sum ys
ptsum (Pt x (Some y) ys) = x + y + sum ys

msum :: Mixed -> Int
msum (Mixed a b) = a + b

result :: String
result = unlines
  [ show (tsum (T 3 4))
  -- the second field is lazy, so an error there is never evaluated
  , show (tfst (T 5 (error "lazy field forced")))
  , show (mag (3 :* 4))
  , show (ptsum (Pt 1 (Some 2) [3, 4]) + ptsum (Pt 10 None []))
  , show (msum (Mixed 6 7))
  ]

main = appendChan stdout result abort done
