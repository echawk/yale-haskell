{-# LANGUAGE ExistentialQuantification #-}
module Main (main) where
import Data.Sequence (Seq, fromList)
import Control.Arrow

data Initializer = forall res . Initializer (IO res) (res -> IO ())

type UnresolvedAction = Seq Initializer -> IO ()

run :: UnresolvedAction -> IO ()
run act = act (fromList [])

main :: IO ()
main = run (\_ -> putStrLn "ok")
