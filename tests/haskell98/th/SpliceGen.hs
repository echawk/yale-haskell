{-# LANGUAGE TemplateHaskell #-}
module SpliceGen (power, sel, greeting, countTo) where
import Language.Haskell.TH

-- \x -> x * x * ... * 1
power :: Int -> Q Exp
power n = do
  x <- newName "x"
  lamE [varP x] (go n (varE x))
  where go 0 _ = litE (integerL 1)
        go k e = infixE (Just e) (varE '(*)) (Just (go (k - 1) e))

-- \(x1, ..., xn) -> xi
sel :: Int -> Int -> Q Exp
sel i n = do
  xs <- mapM (\k -> newName ("x" ++ show k)) [1 .. n]
  lamE [tupP (map varP xs)] (varE (xs !! (i - 1)))

greeting :: Q Exp
greeting = litE (stringL "hello from a splice")

-- [1, 2, ..., n] computed at compile time, with a local helper
countTo :: Int -> Q Exp
countTo n = listE (map (litE . integerL . fromIntegral) [1 .. n])
