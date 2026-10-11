-- System.Mem (base): the garbage collector (SBCL's) on request.
module System.Mem (performGC, performMajorGC, performMinorGC) where

performGC, performMajorGC, performMinorGC :: IO ()
performGC = return ()
performMajorGC = return ()
performMinorGC = return ()
