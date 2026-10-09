-- Helper for reexport-prelude.hs: no declarations, only re-exports of
-- implicitly imported Prelude entities (Haskell 98 allows the empty body).
module ReexPrelude (Maybe(Nothing, Just), Bool(True, False), Either(..), Ordering(..)) where
