-- MonadError through MaybeT, IdentityT and the lazy WriterT, and at
-- Maybe and IO (mtl's; Agda's MaybeT ScopeM).
module Main where

import Control.Monad.Except
import Control.Monad.Trans.Maybe
import Control.Monad.Trans.Identity
import qualified Control.Monad.Trans.Writer.Lazy as WL
import System.IO.Error (userError, ioeGetErrorString)

type M = ExceptT String IO

viaMaybeT :: MaybeT M Int
viaMaybeT = throwError "maybeT" `catchError` \e -> return (length e)

viaIdentityT :: IdentityT M String
viaIdentityT = throwError "identityT" `catchError` \e -> return ("caught " ++ e)

viaWriter :: WL.WriterT [String] M Int
viaWriter = (WL.tell ["lost"] >> throwError "w") `catchError` \_ -> WL.tell ["kept"] >> return 1

main :: IO ()
main = do
  r1 <- runExceptT (runMaybeT viaMaybeT)
  print r1
  r2 <- runExceptT (runIdentityT viaIdentityT)
  print r2
  r3 <- runExceptT (WL.runWriterT viaWriter)
  print r3
  print (catchError (throwError ()) (\() -> Just 'm'))
  s <- throwError (userError "io") `catchError` (return . ioeGetErrorString)
  putStrLn s
