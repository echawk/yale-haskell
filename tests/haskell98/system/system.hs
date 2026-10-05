-- System: getArgs, getProgName, getEnv, system, exitWith.
module Main where

import Prelude hiding (getArgs, getProgName, getEnv)
import System

put :: String -> IO ()
put s = appendChan stdout s abort done

showCode :: ExitCode -> String
showCode ExitSuccess     = "ExitSuccess"
showCode (ExitFailure n) = "ExitFailure " ++ show n

helper :: String
helper = "bin/yale-haskell --haskell98 tests/haskell98/system/ExitHelper.hs"

main :: IO ()
main =
  getArgs `thenIO` \args ->
  put ("args: " ++ show (length args) ++ "\n") `thenIO_`
  getProgName `thenIO` \name ->
  put ("progname: " ++ name ++ "\n") `thenIO_`
  getEnv "PATH" `thenIO` \v ->
  put ("PATH set: " ++ show (not (null v)) ++ "\n") `thenIO_`
  system "exit 0" `thenIO` \c0 ->
  put ("exit 0: " ++ showCode c0 ++ "\n") `thenIO_`
  system "exit 3" `thenIO` \c3 ->
  put ("exit 3: " ++ showCode c3 ++ "\n") `thenIO_`
  system "echo from the shell" `thenIO` \_ ->
  system (helper ++ " 0 \"two words\" x") `thenIO` \h0 ->
  put ("helper 0: " ++ showCode h0 ++ "\n") `thenIO_`
  system (helper ++ " 42") `thenIO` \h42 ->
  put ("helper 42: " ++ showCode h42 ++ "\n") `thenIO_`
  put "before exit\n" `thenIO_`
  exitWith ExitSuccess `thenIO_`
  put "not reached\n"
