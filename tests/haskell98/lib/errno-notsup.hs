import Foreign.C.Error

main :: IO ()
main = print (eNOTSUP /= eOK, eOVERFLOW /= eNOTSUP)
