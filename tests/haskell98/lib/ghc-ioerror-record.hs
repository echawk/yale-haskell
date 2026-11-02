-- GHC.IO.Exception's IOError record: a pattern (hspec-core's
-- IOError {ioe_type = UserError, ioe_description = xs}), its fields, and
-- construction at a kind the runtime does not raise
import GHC.IO.Exception
import Control.Exception

main :: IO ()
main = do
  r <- try (ioError (userError "boom"))
  case r of
    Left (IOError {ioe_type = UserError, ioe_description = xs}) -> putStrLn ("user: " ++ xs)
    Left e -> putStrLn ("other: " ++ show e)
    Right () -> putStrLn "none"
  r2 <- try (readFile "/nonexistent/x")
  case r2 of
    Left e -> print (ioe_type e == NoSuchThing, ioe_filename e, ioe_errno e)
    Right _ -> putStrLn "read"
  let e = IOError Nothing UnsupportedOperation "here" "not supported" Nothing (Just "f")
  print (ioe_type e == UnsupportedOperation, ioe_location e, ioe_description e, ioe_filename e)
