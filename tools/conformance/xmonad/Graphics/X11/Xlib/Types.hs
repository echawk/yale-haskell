-- Graphics.X11.Xlib.Types (X11 package): only the types xmonad's pure
-- core and its tests use (tools/conformance/xmonad.py).
module Graphics.X11.Xlib.Types (Rectangle(..), Position, Dimension) where

import Data.Int (Int32)
import Data.Word (Word32)

type Position = Int32
type Dimension = Word32

data Rectangle = Rectangle
  { rect_x      :: !Position
  , rect_y      :: !Position
  , rect_width  :: !Dimension
  , rect_height :: !Dimension
  } deriving (Eq, Read, Show)
