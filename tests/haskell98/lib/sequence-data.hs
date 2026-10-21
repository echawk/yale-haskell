import Data.Data
import qualified Data.Sequence as S
main = print (dataTypeName (dataTypeOf (S.fromList "ab")), toConstr (S.fromList [1 :: Int]))
