{-# LANGUAGE TemplateHaskell #-}
module Main (main) where
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.ByteString.Char8 as B
import Language.Haskell.TH.Syntax (lift)
import Control.DeepSeq (force, rnf)

main :: IO ()
main = do
  print ($(lift (T.pack "héllo")), $(lift (TL.pack "lazy")), $(lift (B.pack "bytes")))
  print (force (T.pack "x"), rnf (B.pack "y"))
