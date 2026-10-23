module RecFldA where
data Clause = Clause { clauseLHS :: Int, clauseCatchall :: Bool } deriving Show
data Conflict = LitConflict { litType :: Int, litLeft :: Int } deriving Show
data Params = Params { level :: Int, strategy :: Int } deriving Show
defaultParams :: Params
defaultParams = Params 6 0
