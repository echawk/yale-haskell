{-# LANGUAGE CPP #-}
{-# LANGUAGE TemplateHaskellQuotes #-}
import NameQuoteClassA (Inv(..))
import Language.Haskell.TH (Name, nameBase)
data Which = Inv | Other

n :: Name
n = ''Inv
main = putStrLn (nameBase n)
