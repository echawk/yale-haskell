-- GHC.Stack.Types (base): the call-stack types, GHC.Stack's.
module GHC.Stack.Types (
    HasCallStack, CallStack, SrcLoc(..), emptyCallStack, freezeCallStack,
    fromCallSiteList, getCallStack, pushCallStack
  ) where

import GHC.Stack
