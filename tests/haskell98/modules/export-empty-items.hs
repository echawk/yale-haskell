import ExportEmptyB
import Data.Proxy
f :: Proxy Opt -> Syn
f _ = 3
main = print (f Proxy)
