-- System.Directory (the directory package, a subset), for Yale Haskell's
-- Haskell 98 dialect, as old GHCs' (getModificationTime gives a
-- ClockTime): SystemDirectoryBase.hs defines it.
module System.Directory (
    Permissions, readable, writable, executable, searchable,
    createDirectory, createDirectoryIfMissing, removeDirectory,
    removeDirectoryRecursive, removeFile, renameDirectory, renameFile,
    getDirectoryContents, listDirectory, getCurrentDirectory,
    setCurrentDirectory, withCurrentDirectory, doesFileExist,
    doesDirectoryExist, doesPathExist, getPermissions, setPermissions,
    getModificationTime, getHomeDirectory, getTemporaryDirectory,
    copyFile, findExecutable, makeAbsolute,
    canonicalizePath, makeRelativeToCurrentDirectory,
    XdgDirectory(..), getXdgDirectory, getAppUserDataDirectory,
    getUserDocumentsDirectory, exeExtension, findFile, findFiles,
    getFileSize, removePathForcibly, renamePath, pathIsSymbolicLink,
    getSymbolicLinkTarget
  ) where

import SystemDirectoryBase
