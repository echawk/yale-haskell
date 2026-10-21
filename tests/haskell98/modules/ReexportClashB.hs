-- C(..) re-exported where its method putStr clashes with the Prelude's
module ReexportClashB (C(..)) where
import ReexportClashC
