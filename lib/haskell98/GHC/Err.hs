-- GHC.Err (base)
module GHC.Err (error, errorWithoutStackTrace, undefined) where

errorWithoutStackTrace :: String -> a
errorWithoutStackTrace = error
