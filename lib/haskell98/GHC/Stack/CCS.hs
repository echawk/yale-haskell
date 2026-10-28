-- GHC.Stack.CCS (base): cost-centre stacks.  Yale Haskell has no
-- profiling: a program's stack is the null one and has no entries.
module GHC.Stack.CCS (
    CostCentreStack, CostCentre, getCurrentCCS, getCCSOf, clearCCS,
    ccsCC, ccsParent, ccLabel, ccModule, ccSrcSpan, ccsToStrings,
    renderStack, currentCallStack, whoCreated
  ) where

import Foreign.Ptr (Ptr, nullPtr)
import Foreign.C.String (CString)

data CostCentreStack
data CostCentre

getCurrentCCS :: dummy -> IO (Ptr CostCentreStack)
getCurrentCCS _ = return nullPtr

getCCSOf :: a -> IO (Ptr CostCentreStack)
getCCSOf _ = return nullPtr

clearCCS :: IO a -> IO a
clearCCS = id

ccsCC :: Ptr CostCentreStack -> IO (Ptr CostCentre)
ccsCC _ = return nullPtr

ccsParent :: Ptr CostCentreStack -> IO (Ptr CostCentreStack)
ccsParent _ = return nullPtr

ccLabel, ccModule, ccSrcSpan :: Ptr CostCentre -> IO CString
ccLabel _ = return nullPtr
ccModule _ = return nullPtr
ccSrcSpan _ = return nullPtr

ccsToStrings :: Ptr CostCentreStack -> IO [String]
ccsToStrings _ = return []

renderStack :: [String] -> String
renderStack strs = "CallStack (from -prof):" ++ concatMap ("\n  " ++) (reverse strs)

currentCallStack :: IO [String]
currentCallStack = return []

whoCreated :: a -> IO [String]
whoCreated _ = return []
