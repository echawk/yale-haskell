{-# LANGUAGE TypeFamilies #-}
import GHC.Exts (IsList(..))
import qualified Data.Sequence as S
main = print (fromList [1, 2, 3] :: S.Seq Int, toList (S.fromList "ab"))
