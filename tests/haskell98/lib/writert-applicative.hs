import Control.Applicative
import qualified Control.Monad.Trans.Writer.Lazy as L
import qualified Control.Monad.Trans.Writer.Strict as S
import Data.Functor.Identity

-- Applicative m suffices for WriterT's Applicative and Alternative (transformers)
pairUp :: (Monoid w, Applicative m) => L.WriterT w m a -> L.WriterT w m b -> L.WriterT w m (a, b)
pairUp a b = (,) <$> a <*> b

main :: IO ()
main = do
  print (runIdentity (L.runWriterT (pairUp (L.writer (1 :: Int, "a")) (L.writer ('x', "b")))))
  print (runIdentity (S.runWriterT ((+) <$> S.writer (2, "c") <*> S.writer (3 :: Int, "d"))))
  print (L.runWriterT (L.WriterT Nothing <|> L.writer ('y', "e") :: L.WriterT String Maybe Char))
