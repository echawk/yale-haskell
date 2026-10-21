{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- GHC.IO.Exception (base), the part programs use: IOException, which is
-- IOError, and IOErrorType's constructors as patterns over System.IO.Error's
-- kinds (src/runtime/io-errors.mumble).  The runtime has no kind for most
-- of GHC's others; ResourceVanished, NoSuchThing's siblings and the rest
-- match no error the runtime raises.
module GHC.IO.Exception (
    IOException, IOErrorType(AlreadyExists, NoSuchThing, ResourceBusy,
      ResourceExhausted, EOF, IllegalOperation, PermissionDenied, UserError,
      OtherError, ResourceVanished, Interrupted, InvalidArgument,
      InappropriateType, HardwareFault, UnsupportedOperation, TimeExpired,
      UnsatisfiedConstraints, SystemError, ProtocolError),
    ioe_type, ioError, userError, ExitCode(ExitSuccess, ExitFailure)
  ) where

import System.IO.Error
import System (ExitCode(ExitSuccess, ExitFailure))

type IOException = IOError

ioe_type :: IOException -> IOErrorType
ioe_type = ioeGetErrorType

kindIs :: IOErrorType -> IOErrorType -> Bool
kindIs = (==)

-- a kind the runtime never raises
unraised :: Int -> IOErrorType
unraised n = mkIOErrorType n

pattern OtherError :: IOErrorType
pattern OtherError <- (kindIs (mkIOErrorType 0) -> True) where
  OtherError = mkIOErrorType 0
pattern AlreadyExists :: IOErrorType
pattern AlreadyExists <- (kindIs alreadyExistsErrorType -> True) where
  AlreadyExists = alreadyExistsErrorType
pattern NoSuchThing :: IOErrorType
pattern NoSuchThing <- (kindIs doesNotExistErrorType -> True) where
  NoSuchThing = doesNotExistErrorType
pattern ResourceBusy :: IOErrorType
pattern ResourceBusy <- (kindIs alreadyInUseErrorType -> True) where
  ResourceBusy = alreadyInUseErrorType
pattern ResourceExhausted :: IOErrorType
pattern ResourceExhausted <- (kindIs fullErrorType -> True) where
  ResourceExhausted = fullErrorType
pattern EOF :: IOErrorType
pattern EOF <- (kindIs eofErrorType -> True) where
  EOF = eofErrorType
pattern IllegalOperation :: IOErrorType
pattern IllegalOperation <- (kindIs illegalOperationErrorType -> True) where
  IllegalOperation = illegalOperationErrorType
pattern PermissionDenied :: IOErrorType
pattern PermissionDenied <- (kindIs permissionErrorType -> True) where
  PermissionDenied = permissionErrorType
pattern UserError :: IOErrorType
pattern UserError <- (kindIs userErrorType -> True) where
  UserError = userErrorType
pattern ResourceVanished :: IOErrorType
pattern ResourceVanished <- (kindIs (unraised 9) -> True) where
  ResourceVanished = unraised 9
pattern Interrupted :: IOErrorType
pattern Interrupted <- (kindIs (unraised 10) -> True) where
  Interrupted = unraised 10
pattern InvalidArgument :: IOErrorType
pattern InvalidArgument <- (kindIs (unraised 11) -> True) where
  InvalidArgument = unraised 11
pattern InappropriateType :: IOErrorType
pattern InappropriateType <- (kindIs (unraised 12) -> True) where
  InappropriateType = unraised 12
pattern HardwareFault :: IOErrorType
pattern HardwareFault <- (kindIs (unraised 13) -> True) where
  HardwareFault = unraised 13
pattern UnsupportedOperation :: IOErrorType
pattern UnsupportedOperation <- (kindIs (unraised 14) -> True) where
  UnsupportedOperation = unraised 14
pattern TimeExpired :: IOErrorType
pattern TimeExpired <- (kindIs (unraised 15) -> True) where
  TimeExpired = unraised 15
pattern UnsatisfiedConstraints :: IOErrorType
pattern UnsatisfiedConstraints <- (kindIs (unraised 16) -> True) where
  UnsatisfiedConstraints = unraised 16
pattern SystemError :: IOErrorType
pattern SystemError <- (kindIs (unraised 17) -> True) where
  SystemError = unraised 17
pattern ProtocolError :: IOErrorType
pattern ProtocolError <- (kindIs (unraised 18) -> True) where
  ProtocolError = unraised 18
