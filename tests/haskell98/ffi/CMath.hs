module CMath (c_cos, c_hypot) where
foreign import ccall "cos" c_cos :: Double -> Double
foreign import ccall "hypot" c_hypot :: Double -> Double -> Double
