-- Network.BSD (network-bsd): getHostName only (KiCS2's
-- System.Environment).
module Network.BSD (HostName, getHostName) where

import BasePrims (primGetHostName)

type HostName = String

getHostName :: IO HostName
getHostName = primGetHostName
