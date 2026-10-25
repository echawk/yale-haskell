-- GHC.IO.Device (base): the kinds of I/O device a handle can be on
-- (network's socketToHandle names Stream).
module GHC.IO.Device (IODeviceType(..), SeekMode(..)) where

import System.IO (SeekMode(..))

data IODeviceType = Directory | Stream | RegularFile | RawDevice
  deriving (Eq, Show)
