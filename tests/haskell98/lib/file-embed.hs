{-# LANGUAGE TemplateHaskell #-}
module Main where
import Data.FileEmbed
import qualified Data.ByteString.Char8 as B8
main = B8.putStr $(makeRelativeToProject "tests/haskell98/lib/file-embed.stdout" >>= embedFile)
