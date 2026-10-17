-- Helper for empty-export-list.hs: an empty export list exports only
-- the instances (base-orphans, transformers-compat).
module EmptyExportOrphan () where

instance Show (a -> b) where
  show _ = "<function>"

hidden :: Int
hidden = 1
