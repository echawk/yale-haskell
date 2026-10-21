{-# LANGUAGE FlexibleContexts #-}
module FlexibleGivenA (SL(..), T(..)) where
newtype T = T String
class SL s where
  toS :: s -> String
  fromS :: String -> s
  fromT :: SL T => T -> s
  fromT = fromS . toS
