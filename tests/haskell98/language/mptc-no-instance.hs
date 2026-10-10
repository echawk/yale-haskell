-- A multi-parameter constraint no instance provides is an error.
class Convert a b where
  convert :: a -> b
instance Convert Int Bool where
  convert = (> 0)
main :: IO ()
main = print (convert 'x' :: Bool)
