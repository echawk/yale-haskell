-- Test.QuickCheck.Property (QuickCheck 2), a subset: a test's result as a
-- value (succeeded, failed, rejected), with Property and Testable.
module Test.QuickCheck.Property (
    Property, Testable(property), Result(MkResult, ok, reason, theException),
    succeeded, failed, rejected, liftBool, counterexample, once, ioProperty
  ) where

import Test.QuickCheck
import Control.Exception (SomeException)

data Result = MkResult { ok :: Maybe Bool, reason :: String,
                         theException :: Maybe SomeException }

succeeded, failed, rejected :: Result
succeeded = MkResult (Just True) "" Nothing
failed = MkResult (Just False) "" Nothing
rejected = MkResult Nothing "" Nothing

liftBool :: Bool -> Result
liftBool b = MkResult (Just b) "" Nothing

instance Testable Result where
  property r = case ok r of
    Nothing -> False ==> True
    Just b -> case (reason r, theException r) of
      ("", Nothing) -> property b
      ("", Just e) -> counterexample ("Exception thrown: " ++ show e) b
      (why, _) -> counterexample why b
