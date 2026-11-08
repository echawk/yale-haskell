-- coerce between a type variable and a newtype over it, the variable
-- decided by a functional dependency (random's overwriteGen, modifyGen)
import Data.Coerce (coerce)
import Control.Monad.State

newtype SG g = SG { unSG :: g } deriving Show

modifyG :: MonadState g m => (SG g -> (a, SG g)) -> m a
modifyG f = state (coerce f)

overwriteG :: MonadState g m => SG g -> m ()
overwriteG f = put (coerce f)

main :: IO ()
main = print (runState (modifyG (\(SG n) -> (n * 2, SG (n + 1)))) (5 :: Int), execState (overwriteG (SG 9)) (1 :: Int))
