{-# LANGUAGE TemplateHaskell #-}
-- Expression splices of library code: literals, global names whose
-- modules are not imported here (map's PreludeList), built-in syntax,
-- lambdas with mkName's names, and the extensions.py probe.
import Language.Haskell.TH
main :: IO ()
main = do
  print $(litE (integerL (product [1 .. 10])))
  print ($(tupE [conE 'True, litE (stringL "hi"), varE 'map `appE` varE 'negate `appE` listE [litE (integerL 1)]]))
  print ($(lamE [varP (mkName "x")] (infixE (Just (varE (mkName "x"))) (varE '(+)) (Just (litE (integerL 1))))) 41)
  print $(listE [conE '(), conE '()])
  print ($(conE '(:)) 'a' $(conE '[]))
  print (let f = $(varE 'succ) in f 'a')
