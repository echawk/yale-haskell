module SfB where
import {-# SOURCE #-} SfA ((<+>))
greeting :: String
greeting = "hello" <+> "world" <> "."
