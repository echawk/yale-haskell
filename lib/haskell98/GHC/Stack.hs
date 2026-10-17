-- GHC.Stack (base).  Yale Haskell keeps no call stacks: HasCallStack is
-- the empty constraint (a synonym of (), which a context drops:
-- util/signature.mumble's trivial-constraint?), and every CallStack is
-- empty.  Programs that only pass HasCallStack along, or print
-- prettyCallStack, compile and run; the stacks they print are empty.
module GHC.Stack (
    HasCallStack, CallStack, SrcLoc(..),
    callStack, emptyCallStack, freezeCallStack, fromCallSiteList,
    getCallStack, popCallStack, prettyCallStack, prettySrcLoc,
    pushCallStack, withFrozenCallStack, currentCallStack
  ) where

import Data.List (intercalate)

type HasCallStack = ()

data CallStack = EmptyCallStack

instance Show CallStack where
  showsPrec _ _ = showString "[]"

data SrcLoc = SrcLoc
  { srcLocPackage   :: String
  , srcLocModule    :: String
  , srcLocFile      :: String
  , srcLocStartLine :: Int
  , srcLocStartCol  :: Int
  , srcLocEndLine   :: Int
  , srcLocEndCol    :: Int
  } deriving (Eq, Show)

callStack :: CallStack
callStack = EmptyCallStack

emptyCallStack :: CallStack
emptyCallStack = EmptyCallStack

freezeCallStack :: CallStack -> CallStack
freezeCallStack cs = cs

fromCallSiteList :: [(String, SrcLoc)] -> CallStack
fromCallSiteList _ = EmptyCallStack

getCallStack :: CallStack -> [(String, SrcLoc)]
getCallStack _ = []

popCallStack :: CallStack -> CallStack
popCallStack cs = cs

pushCallStack :: (String, SrcLoc) -> CallStack -> CallStack
pushCallStack _ cs = cs

prettySrcLoc :: SrcLoc -> String
prettySrcLoc l = intercalate ":" [srcLocFile l, show (srcLocStartLine l), show (srcLocStartCol l)]
                 ++ " in " ++ srcLocPackage l ++ ":" ++ srcLocModule l

-- GHC prints nothing for an empty stack
prettyCallStack :: CallStack -> String
prettyCallStack _ = ""

withFrozenCallStack :: a -> a
withFrozenCallStack x = x

currentCallStack :: IO [String]
currentCallStack = return []
