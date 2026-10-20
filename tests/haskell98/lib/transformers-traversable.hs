import Control.Monad.Trans.Maybe
import Control.Monad.Trans.Except
import qualified Control.Monad.Trans.Writer.Lazy as WL
import qualified Control.Monad.Trans.Writer.Strict as WS
import Data.Foldable (toList)
main = do
  print (toList (MaybeT [Just 1, Nothing, Just 3]), sum (ExceptT [Left "e", Right 4, Right 5]))
  r <- traverse (\x -> return (x * 10)) (MaybeT [Just 1, Nothing])
  print (runMaybeT r)
  print (toList (WL.WriterT [(1, "a"), (2, "b")]), toList (WS.WriterT (Just ('z', ()))))
  e <- traverse (\x -> return (show x)) (ExceptT [Right 7, Left 'x'])
  print (runExceptT e)
