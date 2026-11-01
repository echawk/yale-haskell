{-# LANGUAGE MagicHash #-}
import GHC.Exts

main :: IO ()
main = do
  print (plusWord8# 200 100, subWord8# 3 5)
  print (plusInt8# 100 100, subInt16# (-32768) 1)
