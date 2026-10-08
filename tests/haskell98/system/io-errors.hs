-- IO: catch, ioError, userError, the IOError predicates, bracket, and
-- errors raised by the System library.
module Main where
import Dialogue (thenIO, thenIO_, returnIO)

import Prelude hiding (stdin, stdout, stderr)
import IO
import System

say :: String -> IO ()
say s = hPutStrLn stdout s

kinds :: IOError -> String
kinds e = concat [ n | (p, n) <- [ (isAlreadyExistsError, " alreadyExists")
                                 , (isDoesNotExistError,  " doesNotExist")
                                 , (isAlreadyInUseError,  " alreadyInUse")
                                 , (isFullError,          " full")
                                 , (isEOFError,           " eof")
                                 , (isIllegalOperation,   " illegalOperation")
                                 , (isPermissionError,    " permission")
                                 , (isUserError,          " user") ],
                             p e ]

fmap' :: (a -> b) -> Maybe a -> Maybe b
fmap' _ Nothing  = Nothing
fmap' f (Just x) = Just (f x)

report :: String -> IOError -> IO ()
report what e = say (what ++ ":" ++ kinds e)

main :: IO ()
main =
  catch (ioError (userError "boom") `thenIO_` say "not reached")
        (\e -> report "userError" e `thenIO_`
               say ("  string: " ++ ioeGetErrorString e) `thenIO_`
               say ("  shown: " ++ show e)) `thenIO_`
  catch (returnIO 41) (\e -> returnIO 0) `thenIO` \n ->
  say ("no error: " ++ show (n + 1 :: Int)) `thenIO_`
  catch (getEnv "YALE_HASKELL_SURELY_UNSET_VARIABLE" `thenIO` \v ->
         say ("got " ++ v))
        (report "getEnv unset") `thenIO_`
  catch (catch (ioError (userError "inner"))
               (\e -> say ("inner handler: " ++ ioeGetErrorString e) `thenIO_`
                      ioError (userError "rethrown")))
        (\e -> say ("outer handler: " ++ ioeGetErrorString e)) `thenIO_`
  catch (bracket (say "acquire" `thenIO_` returnIO 7)
                 (\x -> say ("release " ++ show x))
                 (\x -> say ("use " ++ show x) `thenIO_`
                        ioError (userError "in bracket")))
        (\e -> say ("after bracket: " ++ ioeGetErrorString e)) `thenIO_`
  bracket_ (say "before") (\_ -> say "after") (say "during") `thenIO_`
  catch (openFile "/nonexistent/yale-haskell/file" ReadMode `thenIO_`
         say "opened?")
        (report "openFile missing") `thenIO_`
  catch (hGetLine stdin `thenIO` \l -> say ("read " ++ l))
        (report "hGetLine at EOF") `thenIO_`
  catch (hPutStr stdin "x") (report "hPutStr stdin") `thenIO_`
  try (openFile "/nonexistent/yale-haskell/file" ReadMode) `thenIO` \r ->
  (case r of
     Left e  -> say ("try Left: " ++ show (ioeGetFileName e) ++ " "
                     ++ show (fmap' (const ()) (ioeGetHandle e)))
     Right _ -> say "try Right") `thenIO_`
  try (returnIO 5) `thenIO` \r5 ->
  say (case r5 of { Left _ -> "left"; Right v -> "try Right " ++ show (v :: Int) }) `thenIO_`
  try (ioError (userError "u")) `thenIO` \ru ->
  say (case ru of
         Left e  -> "user: " ++ show (ioeGetFileName e, isUserError e)
         Right () -> "no error") `thenIO_`
  say "done"
