-- mtl's class defaults (state from get and put, reader from ask, writer
-- from tell) and the Report's negate x = 0 - x: an instance leaving them
-- out (Parsec's MonadState, vector's Num Size) used to call error.
import Control.Monad.State
import Control.Monad.Reader
import Control.Monad.Writer
import Text.Parsec
newtype N = N Int deriving (Eq, Show)
instance Num N where
  N a + N b = N (a + b)
  N a - N b = N (a - b)
  N a * N b = N (a * b)
  abs = id
  signum = id
  fromInteger = N . fromInteger
p :: ParsecT String () (State Int) Char
p = do { lift (modify (+1)); n <- lift get; modify (+1); gets (+0); char 'a' }
main = do
  print (negate (N 3))
  print (runState (runParserT p () "" "a") 10)
  print (runReader (reader (+1)) 1, runWriter (writer ((), "w") >> tell "x"))
