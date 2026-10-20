import Foreign.C.Types
main = print (case CTime 5 of CTime n -> n, CInt 3 + 4)
