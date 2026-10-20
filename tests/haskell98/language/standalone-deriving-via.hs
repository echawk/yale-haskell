{-# LANGUAGE DerivingVia, StandaloneDeriving, KindSignatures #-}
module Main (main) where
import Data.Kind (Type)
import Data.Functor.Identity (Identity(..))

class Describe a where describe :: a -> String
instance Describe Bool where describe b = "bool " ++ show b
instance Describe a => Describe (Identity a) where describe (Identity a) = "id(" ++ describe a ++ ")"

class Describe1 f where describe1 :: f Bool -> String
instance Describe1 Identity where describe1 (Identity b) = "id1 " ++ show b

newtype Flag = Flag Bool
newtype Wrap a = Wrap a

deriving via Bool instance Describe Flag
deriving via (a :: Type) instance Describe a => Describe (Wrap a)
deriving via Identity instance Describe1 Wrap

main :: IO ()
main = mapM_ putStrLn [describe (Flag True), describe (Wrap False), describe1 (Wrap True)] >> check

newtype Opt a = Opt (Maybe a)
instance Describe a => Describe (Maybe a) where describe m = maybe "none" describe m
deriving via Maybe a instance Describe a => Describe (Opt a)
check :: IO ()
check = putStrLn (describe (Opt (Just True)))
