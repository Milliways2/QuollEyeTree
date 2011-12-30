QuollEyeTree

"QuollEyeTree" is a Cocoa File Management application for Mac OS X. It requires v10.6 Snow Leopard or later.

QuollEyeTree is inspired by XTree (and its successor ZTreeWin for Windows), but rather than trying to duplicate either, aims to implement the essential functionality, while retaining the Mac look and feel, and honouring the Apple Human Interface Guidelines.

The following sets out the design objectives of QuollEyeTree.

1. Tree Display
QuollEyeTree logs (loads into memory) a subset of the filesystem. The portion of the filesystem logged is controlled by the user.
The logged Directory Tree is displayed as a tree (the Directory Window), which can be used to navigate to a directory.

2. Separate Directory/File Display
The contents of the selected directory are displayed in another pane (the File Window), which may be a part of the main window or expand to take over the whole window. The File Window displays only files.

3. Branch/Global File Display
The File Window may optionally display all files (or tagged files) in a Branch, or all logged files (Global).
This unique ability is a very powerful tool for finding files (duplicate or differing versions), although it may not be obvious until you have used it.

4. File Filtering
The ability to filter files is probably the most powerful feature of the Xtree family.
Every DOS since CP/M allows you to list a subset of files with a command like "dir *.txt", and most modern OS include more powerful filters (such as regular expressions).

5. File Tagging
QuollEyeTree implements persistent file tagging. Files can be tagged by file filter or attribute, and can be extended by tagging or untagging using other criteria. Tagging allows a number of operations to be performed on groups of tagged files, and is particularly helpful in Branch/Global File Display.

6. Keyboard Operation
Most functions in QuollEyeTree can be performed on the keyboard, often with single alphabetic keys, but most can be used with the mouse as well and common GUI features, such as a scrollbar, are used.


Notes for Mac Users
QuollEyeTree loads a subset of the filesystem into memory. Once loaded this does not change, until explicitly updated, and the logged data can become out of date due to asynchronous changes to the filesystem. (This differs from Finder, which automatically updates for changes. QuollEyeTree optionally allows automatic refresh.)


Notes for XTREE Users
Windows supports a number of Drives, and XTREE logs these back to the root of the Drive. UNIX has a single FileSystem and all files are under the root '/'.

When QuollEyeTree 'logs' a directory it loads the path back to the root. Although only the logged directory is initially displayed, all directories back to '/' are loaded into memory. It is possible to select any directory as the apparent root of the display.

Symbolic links (and Mac Aliases) are loaded into the appropriate position in the FileSystem (and the path back to '/' is loaded into memory). No matter how many links point to a target it will only be loaded once.

Wherever possible operations can be performed on the keyboard and the same keys are used as in XTree/ZTreeWin. This is not always possible because some keys are not on the Mac Keyboard or would violate the Apple Human Interface Guidelines.

XTree supports 2 views (Split). Each of these maintains an independent set of tags. QuollEyeTree tags are shared across all Tabs - files tagged in one Tab will be tagged in all. XTree views share the expanded state of directories. Each QuollEyeTree Tab independently manages its own expanded/collapsed state.

Keyboard Differences
Copy and Move are used for both Files and Directories. This is the user expectation in Finder. The XTREE Graft and Prune are tree metaphors, but not obvious.
Delete is not used, the normal Mac shortcut ⌘⌫ is used to delete both Files and Directories.
The XTREE Make is replaced by ⇧⌘N	New Dir as in Finder
