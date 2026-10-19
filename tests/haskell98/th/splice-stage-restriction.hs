{-# LANGUAGE TemplateHaskell #-}
-- A splice may use only imported functions.
import Language.Haskell.TH
five :: Q Exp
five = litE (integerL 5)
main = print $(five)
