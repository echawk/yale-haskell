-- Control.Exception's getMaskingState, allowInterrupt, mapException and
-- ioError (lifted-base).
import qualified Control.Exception as E
data Mine = Mine String deriving Show
instance E.Exception Mine
main = do
  E.getMaskingState >>= print
  E.allowInterrupt
  r <- E.try (E.evaluate (E.mapException (\ (E.ErrorCall s) -> Mine s) (error "boom" :: Int)))
  case r of
    Left (Mine s) -> putStrLn ("mapped " ++ s)
    Right _ -> putStrLn "no"
  E.ioError (userError "x") `E.catch` \ e -> print (e :: IOError)
