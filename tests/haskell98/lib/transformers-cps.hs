-- Control.Monad.Trans.Writer.CPS and RWS.CPS; Data.Array.Byte.
import Data.Array.Byte
import Control.Monad.Trans.Writer.CPS
import qualified Control.Monad.Trans.RWS.CPS as R
main = do
  print (runWriter (tell "ab" >> tell "c" >> return 3))
  print (R.runRWS (R.ask >>= \r -> R.modify (+r) >> R.tell [r] >> R.get) 2 10)
  print (mempty :: ByteArray)
