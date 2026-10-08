module Main where

import Array

-- Dispatch-heavy program: a small stack machine with two registers,
-- interpreting a loop that sums (i*i) `mod` 7 for i = n down to 1.
-- Each step is a case over twelve instruction constructors.

data Instr = PushA | PushB | PopA | PopB | Lit Int
           | Add | Sub | Mul | Mod | Jnz Int | Jmp Int | Halt

program :: Int -> Array Int Instr
program n = listArray (0, length is - 1) is
  where is = [ Lit n, PopA, Lit 0, PopB
             , PushB, PushA, PushA, Mul, Lit 7, Mod, Add, PopB   -- 4: b += a*a mod 7
             , PushA, Lit 1, Sub, PopA                           -- a -= 1
             , PushA, Jnz 4, Halt ]

run :: Array Int Instr -> Int -> Int -> Int -> [Int] -> Int
run prog pc a b st =
  a `seq` b `seq`
  case prog ! pc of
    PushA  -> run prog (pc + 1) a b (a : st)
    PushB  -> run prog (pc + 1) a b (b : st)
    PopA   -> case st of (x : st') -> run prog (pc + 1) x b st'
    PopB   -> case st of (x : st') -> run prog (pc + 1) a x st'
    Lit k  -> run prog (pc + 1) a b (k : st)
    Add    -> arith (+)
    Sub    -> arith (-)
    Mul    -> arith (*)
    Mod    -> arith mod
    Jnz t  -> case st of (x : st') -> run prog (if x /= 0 then t else pc + 1) a b st'
    Jmp t  -> run prog t a b st
    Halt   -> b
  where
    arith f = case st of
                (y : x : st') -> let r = f x y in r `seq` run prog (pc + 1) a b (r : st')

main :: IO ()
main = print (run (program 1000000) 0 0 0 [])
