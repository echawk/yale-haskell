-- A GADT-syntax constructor with only existential variables is matched
-- as an existential, so a local function's monad is inferred (Agda's
-- checkPragmaOptionConsistency).
{-# LANGUAGE GADTs #-}
module Main where

data WithDefault a = Default | Value Bool deriving (Eq, Show)

data Opts = Opts { optA :: WithDefault Int, optB :: WithDefault Char }

data Implied where
  Implies :: String -> Bool -> (Opts -> WithDefault a)
          -> String -> Bool -> (Opts -> WithDefault b) -> Implied

implied :: [Implied]
implied = [Implies "a" True optA "b" False optB]

class Monad m => MonadWarning m where
  warning :: String -> m ()

instance MonadWarning IO where
  warning = putStrLn

checkConsistency :: Opts -> Opts -> IO ()
checkConsistency oldOpts newOpts = do
  mapM_ check implied
  where
    check (Implies nameA valA flagA nameB valB flagB)
      | flagA newOpts == flagA oldOpts
      , flagB newOpts == flagB oldOpts = pure ()
      | Value vA <- flagA newOpts, vA == valA
      , Value vB <- flagB newOpts, vB /= valB = warning (nameA ++ " conflicts with " ++ nameB)
      | otherwise = pure ()

main :: IO ()
main = checkConsistency (Opts Default Default) (Opts (Value True) (Value True))
