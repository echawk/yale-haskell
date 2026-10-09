-- IOBase: Yale Haskell's Handle and HandlePosn types, with their
-- constructors.  Not a library module for programs: IO exports the types
-- abstractly, and System.IO and System.IO.Error use the constructors.
-- (Yale requires instances in the module that defines the type, so the
-- instances are here too.)

module IOBase (Handle(..), HandlePosn(..)) where

import IOPrims

data Handle = Handle HandleObj

instance Eq Handle where
  Handle h1 == Handle h2 = primHandleEq h1 h2

instance  Show Handle  where
  showsPrec _ (Handle h) = showString "{handle: "
                           . showString (primHandleName h) . showChar '}'

data HandlePosn = HandlePosn Handle Integer

instance Eq HandlePosn where
  HandlePosn h1 p1 == HandlePosn h2 p2  =  h1 == h2 && p1 == p2

instance  Show HandlePosn  where
  showsPrec _ (HandlePosn h p) = shows h . showString " at position "
                                 . shows p

