-- Callbacks of other types: Double/Bool, IO (), Char, a pure export.
import Foreign
import Foreign.C.Types

foreign import ccall "wrapper" mkPred :: (Double -> Bool) -> IO (FunPtr (Double -> Bool))
foreign import ccall "dynamic" callPred :: FunPtr (Double -> Bool) -> Double -> Bool
foreign import ccall "wrapper" mkAction :: IO () -> IO (FunPtr (IO ()))
foreign import ccall "dynamic" runAction :: FunPtr (IO ()) -> IO ()
foreign import ccall "wrapper" mkChar :: (Char -> Int -> Char) -> IO (FunPtr (Char -> Int -> Char))
foreign import ccall "dynamic" callChar :: FunPtr (Char -> Int -> Char) -> Char -> Int -> Char
foreign import ccall "&triple" triplePtr :: FunPtr (Int -> Int)
foreign import ccall "dynamic" callInt :: FunPtr (Int -> Int) -> Int -> Int

foreign export ccall triple :: Int -> Int
triple :: Int -> Int
triple x = 3 * x

main :: IO ()
main = do
  p <- mkPred (> 2.5)
  print (map (callPred p) [1.0, 3.0])
  a <- mkAction (putStrLn "called back")
  runAction a
  runAction a
  c <- mkChar (\ch n -> toEnum (fromEnum ch + n))
  print (callChar c 'a' 2, callChar c 'λ' 1)
  print (callInt triplePtr 14)
