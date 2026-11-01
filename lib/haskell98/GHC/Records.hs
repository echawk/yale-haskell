-- GHC.Records (base): the HasField class.  Instances a program writes
-- work; the compiler does not solve HasField "f" R a for R's own field f
-- (OverloadedRecordDot's r.f is f r, parser/exp-parser.mumble).
{-# LANGUAGE FunctionalDependencies, KindSignatures, PolyKinds #-}
module GHC.Records (HasField(getField)) where

class HasField x r a | x r -> a where
  getField :: r -> a
