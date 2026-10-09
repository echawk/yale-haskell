module Main where
import Data.Version
type FieldName = String
type Name = String

newtype Cabal = Cabal [Section]
  deriving (Show)

data Value
  = VItems   [Item]
  | VItem    Item
  | VBool    Bool
  | VVersion Version
  | VRange   VersionRange
  | VPkgs    [(Item, [Item], Maybe VersionRange)]
  | VXItem   String              -- for x-* fields
  deriving (Show)

data Field
  = Field FieldName Value
  | If Cond [Field] [Field]
  deriving (Show)

data Cond
  = CBool Bool
  | Cos Item
  | Carch Item
  | Cimpl Item (Maybe VersionRange)
  | Cflag Item
  | Cnot Cond
  | Cand Cond Cond
  | Cor  Cond Cond
  deriving (Show)

data Section = Section SectionType Name [Field]
  deriving (Show)

type SectionType = String

data VersionRange
  = VEQ Version
  | VGT Version
  | VLT Version
  | VLE Version
  | VGE Version
  | VGEHat Version
  | VEQWild Version
  | VOr VersionRange VersionRange
  | VAnd VersionRange VersionRange
  | VEQSet [Version]
  | VGEHatSet [Version]
  deriving (Show)

type Item = String

data FlagInfo = FlagInfo
  { os    :: String
  , arch  :: String
  , impl  :: (String, Version)
  , flags :: [(Name, Bool)]
  }
  deriving (Show)
main = print (VRange (VEQ (makeVersion [1])))
