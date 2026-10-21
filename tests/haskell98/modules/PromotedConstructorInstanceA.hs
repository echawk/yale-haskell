{-# LANGUAGE DataKinds, FlexibleInstances #-}
module PromotedConstructorInstanceA (X(..), Meta(..), P(..)) where
data P a = P
data Meta = MD Bool Bool
class X d where
  x :: P d -> String
instance X ('MD a b) where x _ = "md"
instance X 'True where x _ = "true"
