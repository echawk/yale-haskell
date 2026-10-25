-- An imported newtype-derived instance as a superclass: its dictionary is
-- the underlying type's, cast to the newtype's (Agda's HasFresh ProblemId
-- over Syntax.Common's Enum ProblemId).  The package's unit is cached, so
-- from the second run on the instance comes from its interface.
import Data.GndP
class Enum i => HF i where
  nf :: i -> i
  nf = succ
instance HF P
main :: IO ()
main = print (nf (P 41), [P 1 .. P 3])
