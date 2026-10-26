-- A data instance of a family named qualified (bitvec's data instance
-- U.Vector Bit), its constructor exported with the family by the
-- qualified name (DataFamQualB) and re-exported (DataFamQualC).
import DataFamQualC
import qualified DataFamQualA as U

f :: U.Vec Bit -> Int
f (BitVec a b) = a + b

main :: IO ()
main = print (f (BitVec 1 2))
