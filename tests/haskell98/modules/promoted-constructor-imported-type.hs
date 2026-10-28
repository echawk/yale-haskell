{-# LANGUAGE DataKinds, GADTs, KindSignatures #-}
-- Under DataKinds a constructor named as an imported type (GHC's Check:
-- PmPat's PmLit beside PmExpr's PmLit) does not hide the type; 'PAT is the
-- promoted constructor.
import PromotedClashA

data PatTy = PAT | VA

data PmPat :: PatTy -> * where
  PmVar :: { pm_var_id :: Int } -> PmPat t
  PmLit :: { pm_lit_lit :: PmLit } -> PmPat t
  PmGrd :: { pm_grd :: [Int] } -> PmPat 'PAT

describe :: PmPat t -> String
describe (PmVar i) = "var " ++ show i
describe (PmLit l) = "lit " ++ show l
describe (PmGrd g) = "grd " ++ show g

main :: IO ()
main = mapM_ putStrLn [describe (PmLit (PmSLit "x") :: PmPat 'VA), describe (PmGrd [1]), describe (PmVar 2 :: PmPat PAT)]
