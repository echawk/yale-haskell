-- IO errors: catch handles an ioError raised with userError, and an
-- uncaught one ends the program with a nonzero exit status after the
-- output so far.  (Modern GHC's Prelude has no catch; for it, import
-- System.IO.Error and use catchIOError.)
module Main where

main :: IO ()
main = do
  catch (ioError (userError "boom") >> putStrLn "not reached")
        (\e -> putStrLn "caught an IOError")
  r <- catch (return "fine") (\e -> return "handler")
  putStrLn r
  putStrLn "last line"
  ioError (userError "uncaught")
  putStrLn "not reached either"
