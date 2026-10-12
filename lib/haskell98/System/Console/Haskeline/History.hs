-- System.Console.Haskeline.History (haskeline): a list of lines.
module System.Console.Haskeline.History (
    History, emptyHistory, addHistory, addHistoryUnlessConsecutiveDupe,
    addHistoryRemovingAllDupes, historyLines, stifleHistory, stifleAmount
  ) where

data History = History [String] (Maybe Int)

instance Show History where
  show (History ls _) = show ls

emptyHistory :: History
emptyHistory = History [] Nothing

addHistory :: String -> History -> History
addHistory l (History ls n) = History (trim n (l : ls)) n

addHistoryUnlessConsecutiveDupe :: String -> History -> History
addHistoryUnlessConsecutiveDupe l h@(History (l' : _) _) | l == l' = h
addHistoryUnlessConsecutiveDupe l h = addHistory l h

addHistoryRemovingAllDupes :: String -> History -> History
addHistoryRemovingAllDupes l (History ls n) = addHistory l (History (filter (/= l) ls) n)

historyLines :: History -> [String]
historyLines (History ls _) = ls

stifleHistory :: Maybe Int -> History -> History
stifleHistory n (History ls _) = History (trim n ls) n

stifleAmount :: History -> Maybe Int
stifleAmount (History _ n) = n

trim :: Maybe Int -> [a] -> [a]
trim Nothing xs = xs
trim (Just n) xs = take n xs
