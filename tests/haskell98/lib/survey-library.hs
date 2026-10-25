-- Library pieces packages use (the Hackage survey): System.IO.Error's
-- ioeSet* and modifyIOError (network), ErrorCallWithLocation (hspec),
-- RecConError (cmdargs), GHC.Stack.Types (safe-exceptions),
-- GHC.RTS.Flags (typed-process).
{-# LANGUAGE PatternSynonyms #-}
import System.IO.Error
import Control.Exception
import GHC.Stack.Types (HasCallStack)
import GHC.RTS.Flags (getConcFlags, ctxtSwitchTime)

main :: IO ()
main = do
  r <- try (modifyIOError (\e -> ioeSetErrorString (ioeSetLocation e "here") "changed")
                          (ioError (userError "orig")))
  case r of
    Left e -> print (ioeGetErrorString e, ioeGetLocation e, isUserError e)
    Right () -> putStrLn "no error"
  case ErrorCall "boom" of
    ErrorCallWithLocation m loc -> print (m, loc)
  r2 <- try (throwIO (RecConError "no field")) :: IO (Either RecConError ())
  print (either show (const "none") r2)
  getConcFlags >>= print . (> 0) . ctxtSwitchTime
