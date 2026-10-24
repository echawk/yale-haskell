{-# LANGUAGE RankNTypes, ScopedTypeVariables #-}
-- Language.Haskell.TH.YaleSplice: Yale Haskell's own, not GHC's.  How a
-- splice's result reaches the compiler (src/compiler/th/splices.mumble):
-- as source text, printed with pprint, that the compiler parses where the
-- splice was.  The built-in syntax's names ((,), (), [], (:)), which pprint
-- qualifies as GHC does (GHC.Internal.Tuple.(,)), are printed as the
-- syntax; other global names stay qualified with their original module,
-- which the compiler resolves even where that module is not imported.
module Language.Haskell.TH.YaleSplice (
    spliceExpText, splicePatText, spliceTypeText, spliceDecsText, spliceTopDeclsText,
    yaleTypedQuote, yaleTypedSplice
  ) where

import Data.Data
import Data.IORef
import Data.Char (isAlpha)
import System.IO.Unsafe (unsafePerformIO)
import Language.Haskell.TH.Syntax
import Language.Haskell.TH.Ppr (pprint)

-- typed Template Haskell, on the untyped: [|| e ||] is
-- yaleTypedQuote [| e |], and $$(c) is $(yaleTypedSplice c)
-- (parser/exp-parser.mumble)
yaleTypedQuote :: Quote m => m Exp -> Code m a
yaleTypedQuote = unsafeCodeCoerce

yaleTypedSplice :: Quote m => Code m a -> m Exp
yaleTypedSplice = unTypeCode

spliceExpText :: Q Exp -> String
spliceExpText q = unsafePerformIO (fmap (pprint . everywhere builtinName) (unQ q >>= finalized))

splicePatText :: Q Pat -> String
splicePatText q = unsafePerformIO (fmap (pprint . everywhere builtinName) (unQ q >>= finalized))

spliceTypeText :: Q Type -> String
spliceTypeText q = unsafePerformIO (fmap (pprint . everywhere builtinName) (unQ q >>= finalized))

spliceDecsText :: Q [Dec] -> String
spliceDecsText q = unsafePerformIO (fmap (pprint . everywhere builtinName) (unQ q >>= finalized))

-- the finalizers addModFinalizer left, run once the splice has (and any
-- they leave in turn)
finalized :: a -> IO a
finalized x = do
  fs <- atomicModifyIORef' yaleModFinalizers (\fs -> ([], fs))
  if null fs then return x else mapM_ unQ fs >> finalized x

-- the declarations addTopDecls added while the splice ran, taken once its
-- text (the argument) is (src/compiler/th/splices.mumble's run-splice):
-- they join the module
spliceTopDeclsText :: String -> String
spliceTopDeclsText text = unsafePerformIO $ do
  ds <- atomicModifyIORef' yaleTopDecls (\ds -> (length text `seq` [], ds))
  return (if null ds then "" else pprint (everywhere builtinName ds))

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
-- a newName's name keeps its unique: pprint would number the names it
-- prints from 0, and those of two splices (addTopDecls's) would clash
unqualifyBuiltin (Name occ (NameU u))
  | take 1 s /= "" && (isAlpha (head s) || head s == '_')
  = Name (mkOccName (s ++ "_" ++ show u)) NameS
  where s = occString occ
unqualifyBuiltin n = n

builtinSyntax :: String -> Bool
builtinSyntax s = s `elem` ["()", "[]", ":"] || take 2 s == "(,"
