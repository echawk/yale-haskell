-- ExitCode is an Exception: a thrown one is caught by type; exitWith
-- still exits (Agda's main rethrows ExitCode).
{-# LANGUAGE ScopedTypeVariables #-}
module Main where
import qualified Control.Exception as E
import System.Exit

main :: IO ()
main = do
  r <- (E.throwIO (ExitFailure 3) >> return "no") `E.catches`
         [ E.Handler $ \(e :: ExitCode) -> return ("caught " ++ show e)
         , E.Handler $ \(e :: E.SomeException) -> return "other" ]
  putStrLn r
  (putStrLn "running" >> exitWith (ExitFailure 2)) `E.catches`
    [ E.Handler $ \(e :: ExitCode) -> E.throw e
    , E.Handler $ \(e :: E.SomeException) -> putStrLn "unknown" ]
