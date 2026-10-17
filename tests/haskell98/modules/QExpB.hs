-- Helper for qualified-export.hs: names imported only qualified, exported
-- by their qualified names (Haskell 98 5.2), under their own names.
module QExpB (C.choice, D.other) where

import qualified QExpA as C
import qualified QExpA as D
