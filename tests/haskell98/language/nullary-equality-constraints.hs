{-# LANGUAGE ConstraintKinds, GADTs #-}
-- Nullary constraints (GHC.Stack's HasCallStack, synonyms of ()) and
-- equality constraints in signatures.
import GHC.Stack
type Partial = HasCallStack
headNote :: Partial => String -> [a] -> a
headNote msg [] = error ("headNote: " ++ msg)
headNote _ (x:_) = x
f :: HasCallStack => Int -> String
f n = show n ++ take 0 (prettyCallStack callStack)
main1 = putStrLn (f (headNote "x" [7])) >> print (length (getCallStack callStack))
type Both a = (Show a, Eq a)
g :: (Show a, a ~ Int) => a -> String
g = show
h :: (Both a, b ~ a) => a -> b -> String
h x y = if x == y then show x else show y
main = main1 >> putStrLn (g 3) >> putStrLn (h True True)
