-- A class's flexible superclass at an application of its variable,
-- through a constraint synonym: IsString (m Doc) of MonadWarning m
-- (Agda's MonadPretty).
{-# LANGUAGE ConstraintKinds, FlexibleContexts, FlexibleInstances, UndecidableSuperClasses, OverloadedStrings #-}
module Main where

import Data.String (IsString(..))

newtype Doc = Doc String deriving Show

instance IsString Doc where fromString = Doc
instance Semigroup Doc where Doc a <> Doc b = Doc (a ++ b)

type MonadPretty m = (Monad m, IsString (m Doc), Semigroup (m Doc))

class MonadPretty m => MonadWarning m where
  addWarning :: Doc -> m ()

instance IsString (IO Doc) where fromString = return . Doc
instance Semigroup (IO Doc) where a <> b = (<>) <$> a <*> b
instance MonadWarning IO where addWarning d = print d

warn :: MonadWarning m => String -> m Doc
warn w = do
  p <- "warning: " <> fromString w
  addWarning p
  return p

main :: IO ()
main = warn "careful" >>= print
