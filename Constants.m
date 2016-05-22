//
//  Constants.m
//
//  Created by Ian Binnie on 24/07/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

// PreferencesController Key Constants
NSString *const PREF_SORT_FIELD = @"sortField";
NSString *const PREF_SORT_DIRECTION = @"ascendingSort";
NSString *const PREF_DIRECTORY_ICON = @"iconInDirectory";
NSString *const PREF_FILE_ICON = @"iconInFile";
NSString *const PREF_HIDDEN_FILES = @"hiddenFiles";
NSString *const PREF_AUTOMATIC_REFRESH = @"automaticRefresh";
NSString *const PREF_SPLIT_PERCENTAGE = @"splitPercentage";
NSString *const PREF_SPLIT_PERCENTAGE_H = @"splitPercentageVert";
NSString *const PREF_SPLIT_ORIENTATION = @"splitVertical";
NSString *const PREF_DEFAULT_DIR = @"defaultDirectory";
NSString *const PREF_REFRESH_DIR = @"refreshDirectory";

NSString *const PREF_FILE_COLUMN_WIDTH = @"FileColumnWidth";
NSString *const PREF_FILE_COLUMN_HIDDEN = @"FileColumnHidden";
NSString *const PREF_FILE_COLUMN_ORDER = @"FileColumnOrder";
NSString *const PREF_DIR_COLUMN_WIDTH = @"DirColumnWidth";
NSString *const PREF_DIR_COLUMN_HIDDEN = @"DirColumnHidden";
NSString *const PREF_DIR_COLUMN_ORDER = @"DirColumnOrder";

NSString *const PREF_FILE_RIGHT_COLUMN_WIDTH = @"FileRColumnWidth";
NSString *const PREF_FILE_RIGHT_COLUMN_HIDDEN = @"FileRColumnHidden";
NSString *const PREF_FILE_RIGHT_COLUMN_ORDER = @"FileRColumnOrder";
NSString *const PREF_DIR_LEFT_COLUMN_WIDTH = @"DirLColumnWidth";
NSString *const PREF_DIR_LEFT_COLUMN_HIDDEN = @"DirLColumnHidden";
NSString *const PREF_DIR_LEFT_COLUMN_ORDER = @"DirLColumnOrder";

NSString *const PREF_DATE_WIDTH = @"DateWidth";
NSString *const PREF_DATE_RELATIVE = @"relativeDate";
NSString *const PREF_DATE_FORMAT = @"dateFormat";
NSString *const PREF_DATE_SHOW_CREATE = @"createTime";
NSString *const PREF_SIZE_MODE = @"sizeMode";
NSString *const PREF_TOTAL_MODE = @"totalMode";
NSString *const PREF_COMPARE_COMMAND = @"compareCommand";
NSString *const DEFAULT_COMPARE_COMMAND = @"sdiff -l --strip-trailing-cr $1 $2";	// if changed, also change value in CompareCmds.plist
NSString *const PREF_EDIT_COMMAND = @"editorCommand";
NSString *const DEFAULT_EDIT_COMMAND = @"TextEdit.app";
NSString *const PREF_BATCH_CMD =@"batchCmd";

NSString *const PreferencesControllerDateWidthsDidChangeNotification = @"DateChanged";
NSString *const DirectoryItemDidRemoveDirectoriesNotification = @"DirectoriesRemoved";

// Column Identifier Key Constants
NSString *const COLUMNID_NAME = @"relativePath";
NSString *const COLUMNID_DATE = @"wDate";
NSString *const COLUMNID_CREATION = @"cDate";
NSString *const COLUMNID_SIZE = @"fileSize";
NSString *const COLUMNID_KIND = @"kind";
NSString *const COLUMNID_TAG = @"tag";


