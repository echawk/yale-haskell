-- A dynamic import whose result is a synonym for a function type (X11's
-- getXErrorHandler :: FunPtr CXErrorHandler -> CXErrorHandler), and a
-- descriptor through Storable (network's control messages).
import Foreign
import Foreign.C.Types
import System.Posix.Types (Fd(..))

type Handler = CInt -> IO CInt
foreign import ccall "wrapper" mkHandler :: Handler -> IO (FunPtr Handler)
foreign import ccall "dynamic" callHandler :: FunPtr Handler -> Handler

main :: IO ()
main = do
  p <- mkHandler (\n -> return (n * 2))
  callHandler p 21 >>= print
  freeHaskellFunPtr p
  n <- alloca $ \q -> poke q (Fd 9) >> peek q
  print (n, sizeOf n)
