-- helper for qualified-dot-operator.hs
module QualDotOp ((.:)) where
(.:) :: Int -> Int -> Int
a .: b = a * 10 + b
