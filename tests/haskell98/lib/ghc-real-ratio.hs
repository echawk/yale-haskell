-- GHC.Real's Ratio(..) brings (:%) (bundled); GHC.Stack has the CCS functions.
import GHC.Real (Ratio(..))
import GHC.Stack
f :: Ratio Int -> Int
f (a :% b) = a + b
main = do
  print (f (3 :% 5))
  s <- ccsToStrings =<< getCurrentCCS ()
  putStrLn (renderStack s)
