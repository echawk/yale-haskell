-- System.Posix.Signals (unix), a subset: installing handlers (a Catch
-- handler's action runs when the signal arrives) and raising signals.
module System.Posix.Signals (
    Signal, Handler(Default, Ignore, Catch, CatchOnce),
    installHandler, raiseSignal,
    sigINT, sigHUP, sigABRT, sigALRM, sigTERM, sigPIPE, sigQUIT, sigKILL,
    sigUSR1, sigUSR2, sigCHLD
  ) where

import PosixPrims
import Foreign.C.Types (CInt)

type Signal = CInt

data Handler = Default | Ignore | Catch (IO ()) | CatchOnce (IO ())

sig :: String -> Signal
sig name = fromIntegral (primSignalNumber name)

sigINT, sigHUP, sigABRT, sigALRM, sigTERM, sigPIPE, sigQUIT, sigKILL,
  sigUSR1, sigUSR2, sigCHLD :: Signal
sigINT = sig "INT"
sigHUP = sig "HUP"
sigABRT = sig "ABRT"
sigALRM = sig "ALRM"
sigTERM = sig "TERM"
sigPIPE = sig "PIPE"
sigQUIT = sig "QUIT"
sigKILL = sig "KILL"
sigUSR1 = sig "USR1"
sigUSR2 = sig "USR2"
sigCHLD = sig "CHLD"

-- The previous handler is not known: Default is returned.
installHandler :: Signal -> Handler -> Maybe () -> IO Handler
installHandler s h _ = do
  let n = fromIntegral s
  case h of
    Default -> primInstallSignalHandler n 0 (return ())
    Ignore -> primInstallSignalHandler n 1 (return ())
    Catch act -> primInstallSignalHandler n 2 act
    CatchOnce act -> primInstallSignalHandler n 2 (act >> primInstallSignalHandler n 0 (return ()))
  return Default

raiseSignal :: Signal -> IO ()
raiseSignal s = primRaiseSignal (fromIntegral s)
