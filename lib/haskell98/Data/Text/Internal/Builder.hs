-- Data.Text.Internal.Builder (text): the Builder, as Data.Text.Lazy.Builder
-- has it (Yale Haskell's Text holds Chars: there is no array to write
-- into, so writeN and the like are not here).
module Data.Text.Internal.Builder (module Data.Text.Lazy.Builder) where

import Data.Text.Lazy.Builder
