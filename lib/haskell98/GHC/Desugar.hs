{-# LANGUAGE ExistentialQuantification #-}
-- GHC.Desugar (base): what GHC's desugarer refers to, for GHC's own
-- sources: an annotation's value (ANN pragmas) and arrows' (>>>).
module GHC.Desugar (AnnotationWrapper(..), toAnnotationWrapper, (>>>)) where

import Control.Arrow (Arrow, (>>>))
import Data.Data (Data)

data AnnotationWrapper = forall a. Data a => AnnotationWrapper a

toAnnotationWrapper :: Data a => a -> AnnotationWrapper
toAnnotationWrapper what = AnnotationWrapper what
