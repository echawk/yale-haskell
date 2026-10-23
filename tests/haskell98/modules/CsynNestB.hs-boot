module CsynNestB where
class Monad m => Warn m where
  warn :: String -> m ()
