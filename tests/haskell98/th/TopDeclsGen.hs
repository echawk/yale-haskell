{-# LANGUAGE TemplateHaskell #-}
-- TopDeclsGen: splices that add declarations with addTopDecls and leave
-- actions with addModFinalizer (the top-decls test).
module TopDeclsGen (squareOf, countedTwice) where

import Language.Haskell.TH
import Language.Haskell.TH.Syntax (addTopDecls, addModFinalizer)

-- a helper declared at the top level, the splice a call of it
squareOf :: Integer -> Q Exp
squareOf n = do
  f <- newName "square"
  x <- newName "x"
  addTopDecls [ SigD f (AppT (AppT ArrowT (ConT ''Integer)) (ConT ''Integer))
              , FunD f [Clause [VarP x] (NormalB (InfixE (Just (VarE x)) (VarE '(*)) (Just (VarE x)))) []] ]
  return (AppE (VarE f) (LitE (IntegerL n)))

-- a finalizer that adds a declaration in turn
countedTwice :: Q [Dec]
countedTwice = do
  addModFinalizer $ do
    let n = mkName "finalized"
    addTopDecls [ValD (VarP n) (NormalB (LitE (StringL "finalizer ran"))) []]
  return []
