{-# LANGUAGE TemplateHaskell #-}
-- Test.QuickCheck.All (QuickCheck): testing all the properties of a module,
-- as QuickCheck's: $(quickCheckAll) finds the prop_ definitions by reading
-- the module's source file (Template Haskell's location) and runs each.
module Test.QuickCheck.All (
    quickCheckAll, verboseCheckAll, forAllProperties, allProperties,
    runQuickCheckAll, monomorphic
  ) where

import Language.Haskell.TH
import Test.QuickCheck
import Data.Char (isAlphaNum, isSpace)
import Data.List (isPrefixOf, nubBy)
import Control.Monad (forM)

-- | Test all properties in the current module, as $(quickCheckAll):
-- an IO Bool, True when all pass.
quickCheckAll :: Q Exp
quickCheckAll = [| $(forAllProperties) quickCheckResult |]

-- | As quickCheckAll, verbosely (here: the same).
verboseCheckAll :: Q Exp
verboseCheckAll = [| $(forAllProperties) quickCheckResult |]

-- | The module's properties, as a function of how to check one.
forAllProperties :: Q Exp
forAllProperties = [| runQuickCheckAll $(allProperties) |]

-- | The module's properties, with their names and lines.
allProperties :: Q Exp
allProperties = do
  Loc { loc_filename = filename } <- location
  ls <- runIO (fmap lines (readFile filename))
  let prefixes = map (takeWhile (\c -> isAlphaNum c || c == '_' || c == '\'')
                      . dropWhile (\c -> isSpace c || c == '>')) ls
      idents = nubBy (\x y -> snd x == snd y)
                     (filter (("prop_" `isPrefixOf`) . snd) (zip [1 :: Int ..] prefixes))
      one (l, x) = do
        exists <- (reportWarning ("Name " ++ x ++ " found in source file but was not in scope")
                   >> return False)
                  `recover` (reify (mkName x) >> return True)
        if exists
          then fmap (: []) (tupE [stringE (x ++ " from " ++ filename ++ ":" ++ show l),
                                  [| property $(monomorphic (mkName x)) |]])
          else return []
  fmap (ListE . concat) (mapM one idents)

-- | A property at a monomorphic type: here, the name itself.
monomorphic :: Name -> Q Exp
monomorphic = varE

-- | Checks each named property, printing its name; True when all pass.
runQuickCheckAll :: [(String, Property)] -> (Property -> IO Result) -> IO Bool
runQuickCheckAll ps qc = fmap and . forM ps $ \(xs, p) -> do
  putStrLn ("=== " ++ xs ++ " ===")
  r <- qc p
  putStrLn ""
  return (isSuccess r)
