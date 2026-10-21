{-# LANGUAGE PatternSynonyms, ViewPatterns, GADTs, ScopedTypeVariables, BangPatterns #-}
import Unsafe.Coerce (unsafeCoerce)

newtype Nattish zero succ n = Nattish Int
data Res zero succ n where
  ResZero :: Res zero succ zero
  ResSucc :: Nattish zero succ n -> Res zero succ (succ n)

check :: Nattish zero succ n -> Res zero succ n
check (Nattish 0) = unsafeCoerce ResZero
check (Nattish n) = unsafeCoerce (ResSucc (Nattish (n - 1)))

pattern Zeroy :: () => n ~ zero => Nattish zero succ n
pattern Zeroy <- (check -> ResZero)
pattern Succy :: () => n ~ succ n' => Nattish zero succ n' -> Nattish zero succ n
pattern Succy n <- (check -> ResSucc n)

newtype Zero k a = Zero a
data Succ rk k a = Succ (rk k a) (rk k a)

count :: Nattish Zero Succ rk -> rk k a -> Int
count Zeroy (Zero _) = 1
count (Succy r) (Succ x y) = count r x + count r y

main :: IO ()
main = print (count (Nattish 1 :: Nattish Zero Succ (Succ Zero)) (Succ (Zero 'a') (Zero 'b')))
