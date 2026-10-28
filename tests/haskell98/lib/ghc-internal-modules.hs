-- base's GHC.Real (:%), GHC.Stack.CCS, GHC.IO.Encoding.UTF8/Failure and
-- GHC.Desugar, as GHC 8.0.2's compiler imports them.
{-# LANGUAGE PatternSynonyms #-}
import GHC.Real (Ratio(..), pattern (:%))
import GHC.Stack.CCS
import GHC.IO.Encoding.UTF8 (mkUTF8)
import GHC.IO.Encoding.Failure (CodingFailureMode(..))
import GHC.Desugar
import System.IO

f :: Ratio Int -> (Int, Int)
f (a :% b) = (a, b)

main = do
  print (f (6 :% 4))
  currentCallStack >>= print
  hSetEncoding stdout (mkUTF8 IgnoreCodingFailure)
  case toAnnotationWrapper "x" of AnnotationWrapper _ -> putStrLn "ann"
