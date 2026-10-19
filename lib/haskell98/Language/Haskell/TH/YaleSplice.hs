{-# LANGUAGE RankNTypes, ScopedTypeVariables #-}
-- Language.Haskell.TH.YaleSplice: Yale Haskell's own, not GHC's.  How a
-- splice's result reaches the compiler (src/compiler/th/splices.mumble):
-- as source text, printed with pprint, that the compiler parses where the
-- splice was.  The built-in syntax's names ((,), (), [], (:)), which pprint
-- qualifies as GHC does (GHC.Internal.Tuple.(,)), are printed as the
-- syntax; other global names stay qualified with their original module,
-- which the compiler resolves even where that module is not imported.
module Language.Haskell.TH.YaleSplice (spliceExpText, spliceDecsText) where

import Data.Data
import System.IO.Unsafe (unsafePerformIO)
import Language.Haskell.TH.Syntax
import Language.Haskell.TH.Ppr (pprint)

spliceExpText :: Q Exp -> String
spliceExpText q = unsafePerformIO (fmap (pprint . everywhere builtinName) (unQ q))

spliceDecsText :: Q [Dec] -> String
spliceDecsText q = unsafePerformIO (fmap (pprint . everywhere builtinName) (unQ q))

everywhere :: (forall a. Data a => a -> a) -> (forall a. Data a => a -> a)
everywhere f x = f (gmapT (everywhere f) x)

builtinName :: forall a. Data a => a -> a
builtinName x = case cast x of
  Just n  -> case cast (unqualifyBuiltin n) of
               Just y  -> y
               Nothing -> x
  Nothing -> x

unqualifyBuiltin :: Name -> Name
unqualifyBuiltin n@(Name occ (NameG _ _ m))
  | modString m `elem` ["GHC.Internal.Tuple", "GHC.Internal.Types"]
  , builtinSyntax (occString occ) = Name occ NameS
  | otherwise = n
unqualifyBuiltin n = n

builtinSyntax :: String -> Bool
builtinSyntax s = s `elem` ["()", "[]", ":"] || take 2 s == "(,"
