{-# LANGUAGE TemplateHaskell #-}
module TTHGen where
import Language.Haskell.TH
import Language.Haskell.TH.Syntax

power :: Int -> Code Q (Int -> Int)
power 0 = [|| \_ -> 1 ||]
power n = [|| \x -> x * $$(power (n - 1)) x ||]

safeDiv :: Int -> Code Q Int
safeDiv d = [|| 100 `div` d ||]
