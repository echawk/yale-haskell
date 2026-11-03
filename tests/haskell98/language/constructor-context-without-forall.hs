-- a constructor's context without a forall, on the type's own variables
-- (GHC accepts it: lens' data Answer b a = b ~ a => Hit a)
{-# LANGUAGE ExistentialQuantification #-}
data P a = Show a => P a | Q
showP :: P a -> String
showP (P x) = show x
showP Q = "q"
main :: IO ()
main = putStrLn (showP (P (5 :: Int)) ++ showP (Q :: P Int))
