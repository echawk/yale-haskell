-- An instance context at a data type whose instance wants a family
-- application (megaparsec's (Show (ParseError s e), Show s) => Show
-- (State s e), Show (ParseError s e) wanting Show (Token s)): given as is.
{-# LANGUAGE TypeFamilies, StandaloneDeriving, FlexibleContexts, UndecidableInstances, DeriveGeneric #-}
import GHC.Generics (Generic)
import Control.DeepSeq
import Data.List.NonEmpty (NonEmpty(..))

class Ord (Token s) => Stream s where
  type Token s :: *
  tok :: s -> Token s

instance Stream [a] where
  type Token [a] = a
  tok = head

data PE s e = PE (Maybe (Token s)) | FE e
  deriving (Generic)
deriving instance (Show (Token s), Show e) => Show (PE s e)
deriving instance (Eq (Token s), Eq e) => Eq (PE s e)
instance (NFData (Token s), NFData e) => NFData (PE s e)

data PS s = PS { psInput :: s, psOff :: Int } deriving (Show, Eq, Generic)
instance NFData s => NFData (PS s)

data PB s e = PB { bErrs :: NonEmpty (PE s e), bPos :: PS s }
  deriving (Generic)
deriving instance (Show s, Show (Token s), Show e) => Show (PB s e)
deriving instance (Eq s, Eq (Token s), Eq e) => Eq (PB s e)
instance (NFData s, NFData (Token s), NFData e) => NFData (PB s e)

data St s e = St { stIn :: s, stErrs :: [PE s e] } deriving (Generic)
deriving instance (Show (PE s e), Show s) => Show (St s e)
deriving instance (Eq (PE s e), Eq s) => Eq (St s e)
instance (NFData s, NFData (PE s e)) => NFData (St s e)

main = do
  let st = St "ab" [PE (Just 'y')] :: St String ()
  print st
  print (st == st)
  st `deepseq` putStrLn "ok st"

  let b = PB (PE (Just 'x') :| [FE ()]) (PS "abc" 0) :: PB String ()
  print b
  print (b == b)
  b `deepseq` putStrLn "ok"
