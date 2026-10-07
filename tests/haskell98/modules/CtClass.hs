module CtClass (Describe(describe)) where

class Describe a where
  describe :: a -> String
