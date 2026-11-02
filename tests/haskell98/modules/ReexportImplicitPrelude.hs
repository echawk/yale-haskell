-- module Prelude exported by a module that imports it only implicitly
-- (hspec's Test.Hspec.Discover)
module ReexportImplicitPrelude (foo, module Prelude) where
foo :: Int
foo = 3
