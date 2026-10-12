-- GHC.Generics (base): only the class.  Its representation types need
-- type families, which Yale Haskell does not have; deriving Generic
-- gives an empty instance (derived/derived-instances.mumble), enough
-- for programs that derive it for a library's sake.
module GHC.Generics (Generic, Generic1) where

class Generic a
class Generic1 f
