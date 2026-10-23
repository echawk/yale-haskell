module Main where
import Control.Applicative (Alternative(empty))
import Control.Monad (guard, zipWithM_)
import Control.Monad.Writer (MonadWriter(..), WriterT, execWriterT)
import qualified Data.Map as Map
import Data.Map (Map)

data Pat = VarP String | LitP Int | ConP [Pat]
data Expr = Lit Int | App [Expr] deriving Show

type Match e = WriterT (Map String e) Maybe

(==>) :: String -> e -> Match e ()
x ==> e = tell (Map.singleton x e)

runMatch :: (Pat -> e -> Match e ()) -> Pat -> e -> Maybe (Map String e)
runMatch match pat e = execWriterT (match pat e)

matchP :: Pat -> Expr -> Maybe (Map String Expr)
matchP = runMatch match
  where
    match (VarP x) e = x ==> e
    match (LitP l) (Lit l') = guard (l == l')
    match (ConP ps) e = do
      App args <- return e
      guard $ length ps == length args
      zipWithM_ match ps args
    match _ _ = empty

main :: IO ()
main = print (matchP (ConP [VarP "x", LitP 1]) (App [Lit 5, Lit 1]))
