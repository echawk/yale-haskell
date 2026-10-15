-- Test.QuickCheck.Property (QuickCheck 2), a subset: a test's result as a
-- value (succeeded, failed, rejected), with Property and Testable.
module Test.QuickCheck.Property (
    Property, Testable(property), Result(MkResult, ok, reason),
    succeeded, failed, rejected, liftBool, counterexample, once, ioProperty
  ) where

import Test.QuickCheck

data Result = MkResult { ok :: Maybe Bool, reason :: String }

succeeded, failed, rejected :: Result
succeeded = MkResult (Just True) ""
failed = MkResult (Just False) ""
rejected = MkResult Nothing ""

liftBool :: Bool -> Result
liftBool b = MkResult (Just b) ""

instance Testable Result where
  property r = case ok r of
    Nothing -> False ==> True
    Just b -> if null (reason r) then property b else counterexample (reason r) b
