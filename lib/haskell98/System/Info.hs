-- System.Info (base), for Yale Haskell's Haskell 98 dialect, in GHC's
-- spelling (os "darwin", "linux"; arch "x86_64", "aarch64").
module System.Info (os, arch, compilerName, compilerVersion, fullCompilerVersion) where

import Data.Version
import BasePrims

os :: String
os = primOS

arch :: String
arch = primArch

compilerName :: String
compilerName = "yale-haskell"

compilerVersion :: Version
compilerVersion = makeVersion [2, 0]

fullCompilerVersion :: Version
fullCompilerVersion = makeVersion [2, 0, 6]
