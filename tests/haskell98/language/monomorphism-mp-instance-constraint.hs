-- The monomorphism restriction with a multi-parameter constraint an instance
-- decides only later (JHC's let x = atom (pprint con), by DocLike d => PPrint
-- d Tycon): x is not generalized, its use deciding d.
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, NoMonoLocalBinds #-}
module Main where
class Doc d where txt :: String -> d
instance Doc String where txt = id
class Doc d => PP d a where pp :: a -> d
instance Doc d => PP d Int where pp = txt . show

f :: Int -> String
f n = let x = pp n in x ++ "!"

main = putStrLn (f 3)
