-- A GADT constructor's constraint on its result's variable is given by
-- a match (NFData opts of Agda's BackendWithOpts).
{-# LANGUAGE GADTs, ExistentialQuantification, RankNTypes #-}
module Main where

import Data.Functor ((<&>))

class NFData a where rnf :: a -> String
instance NFData Int where rnf n = "int " ++ show n
instance NFData Bool where rnf b = "bool " ++ show b

data Backend' opts env = Backend' { backendName :: String, options :: opts, env :: env }

data Backend where
  Backend :: NFData opts => Backend' opts env -> Backend

data BackendWithOpts opts where
  BackendWithOpts :: NFData opts => Backend' opts env -> BackendWithOpts opts

forgetOpts :: BackendWithOpts opts -> Backend
forgetOpts (BackendWithOpts backend) = Backend backend

type Lens' o i = forall f. Functor f => (i -> f i) -> o -> f o

bOptions :: Lens' (BackendWithOpts opts) opts
bOptions f (BackendWithOpts b) = f (options b) <&> \ opts -> BackendWithOpts b{ options = opts }

describe :: Backend -> String
describe (Backend b) = backendName b ++ ": " ++ rnf (options b)

newtype Id a = Id { runId :: a }
instance Functor Id where fmap f (Id a) = Id (f a)

main :: IO ()
main = do
  let bw = BackendWithOpts (Backend' "ghc" (3 :: Int) "env")
  putStrLn (describe (forgetOpts bw))
  putStrLn (describe (forgetOpts (runId (bOptions (\o -> Id (o + 1)) bw))))
