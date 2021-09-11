/*
 *  PlayListCtrllr.m
 *  MPlayer OS X
 *
 *  Created by Jan Volf
 *	<javol@seznam.cz>
 *  Copyright (c) 2003 Jan Volf. All rights reserved.
 */
#import "PlayListCtrllr.h"

// other controllers
#import "PlayerCtrllr.h"
#import "AppController.h"
#import "SettingsController.h"

@implementation PlayListCtrllr

/************************************************************************************/
-(void)awakeFromNib
{	    
	// configure playlist table
	[playListTable setTarget:self];
	[playListTable setDoubleAction:@selector(doubleClick:)];
#ifdef __APPLE__
	[playListTable setVerticalMotionCanBeginDrag:YES];
#endif
	
	// load playlist from preferences
#ifdef __APPLE__ 	
 	if ((NSArray *)CFPreferencesCopyAppValue((CFStringRef)@"PlayList",
 			kCFPreferencesCurrentApplication)) {
	  // if play list exists load playlist from preferences
	  myData = [[NSMutableArray alloc] initWithArray:(NSArray *)CFPreferencesCopyAppValue((CFStringRef)@"PlayList",
											      kCFPreferencesCurrentApplication)];
	}
 	else {
	  // if no playlist found
	  myData = [[NSMutableArray alloc] init];	// create new one
 	}
#else
	NSUserDefaults *preferences = [appController preferences];
	
	if ( [preferences objectForKey:@"PlayList"] ) 
	  {
	    myData = [[NSMutableArray alloc] initWithArray: [preferences objectForKey:@"PlayList"]];
	  }
	else {
	  // if no playilist found
	  myData = [[NSMutableArray alloc] init];	// create new one
	}
#endif
	//	[myData retain];
     // register for dragged types
	[playListTable registerForDraggedTypes:[NSArray 
			arrayWithObjects:NSFilenamesPboardType,@"PlaylistSelectionEnumeratorType",nil]];

    // register for app launch finish
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(appFinishedLaunching)
			name: NSApplicationDidFinishLaunchingNotification
			object:NSApp];
	// register for app termination notification
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(appTerminating)
			name: NSApplicationWillTerminateNotification
			object:NSApp];
    // register for app pre-termination notification
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(appShouldTerminate)
			name: @"ApplicationShouldTerminateNotification"
			object:NSApp];

	// register for table selection change notification
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(updateView) 
			name: NSTableViewSelectionDidChangeNotification
			object:playListTable];
	
	// preset status column for displaying pictures
	[[playListTable tableColumnWithIdentifier:@"status"]
			setDataCell:[[NSImageCell alloc] initImageCell:nil]];
	
	// load images
	statusIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
							pathForResource:@"playing_state"
							ofType:@"tiff"]];
	playMode0Image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
							pathForResource:@"play_mode_0"
							ofType:@"tiff"]];
	playMode1Image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
							pathForResource:@"play_mode_1"
							ofType:@"tiff"]];
	playMode2Image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
							pathForResource:@"play_mode_2"
							ofType:@"tiff"]];

	// set play mode
	if ([[appController preferences] objectForKey:@"PlayMode"])
		myPlayMode = [[[appController preferences] objectForKey:@"PlayMode"]
				intValue];
	else
		myPlayMode = 0;
	
	[self applyPrefs];
}

/************************************************************************************
 INTERFACE
 ************************************************************************************/
- (NSMutableDictionary *) itemAtIndex:(int) aIndex
{
	if (aIndex >= 0 || aIndex < [myData count])
		return [myData objectAtIndex:aIndex];
	else
		return nil;
}
/************************************************************************************/
- (void) selectItemAtIndex:(int) aIndex
{
	[playListTable selectRow:aIndex byExtendingSelection:NO];
}
/************************************************************************************/
- (NSMutableDictionary *) selectedItem
{
	return [self itemAtIndex:[playListTable selectedRow]];
}
/************************************************************************************/
- (int) indexOfSelectedItem
{
	return [playListTable selectedRow];
}
/************************************************************************************/
- (int) numberOfSelectedItems
{
	return [playListTable numberOfSelectedRows];
}
/************************************************************************************/
- (int) indexOfItem:(NSDictionary *)anItem
{
	if ([myData count] > 0 && anItem) {
		unsigned aIndex = [myData indexOfObjectIdenticalTo:anItem];
		if (aIndex != NSNotFound)
			return aIndex;
	}
	return -1;
}
/************************************************************************************/
- (int) itemCount
{
	return [myData count];
}
/************************************************************************************/
- (void) appendItem:(NSMutableDictionary *)anItem
{
	if (anItem)
	  [myData addObject:anItem];

	[playListTable reloadData]; //GNUStep only ?????
}
/************************************************************************************/
- (void) insertItem:(NSMutableDictionary *)anItem atIndex:(int) aIndex
{
	if (anItem && aIndex >= 0 && aIndex <= [myData count])
		[myData insertObject:anItem atIndex:aIndex];
}
/************************************************************************************/
- (IBAction)deleteSelection:(id) sender
{
	id myObject;
	// get and sort enumerator in descending order
	NSEnumerator *selectedItemsEnum = [[[[playListTable selectedRowEnumerator] allObjects]
			sortedArrayUsingSelector:@selector(compare:)] reverseObjectEnumerator];
	
	// remove object in descending order
	myObject = [selectedItemsEnum nextObject];
	while (myObject) {
		[myData removeObjectAtIndex:[myObject intValue]];
		myObject = [selectedItemsEnum nextObject];
	}
	[playListTable deselectAll:nil];
	[self updateView];
}
/************************************************************************************/
- (void) updateView
{
	[playListTable reloadData];
	
	if ([playListTable selectedRow] < 0 || [playListTable numberOfSelectedRows] > 1 ||
			[settingsController isVisible]) {
		[settingsButton setEnabled:NO];
	}
	else {
		[settingsButton setEnabled:YES];
	}
	
	switch (myPlayMode) {
	case 1:
		[playModeButton setImage:playMode1Image];
		[playModeButton setToolTip:NSLocalizedString(@"Play mode: Continous",nil)];
		break;
	case 2:
		[playModeButton setImage:playMode2Image];
		[playModeButton setToolTip:NSLocalizedString(@"Play mode: Repeating",nil)];
		break;
	default:
		[playModeButton setImage:playMode0Image];
		[playModeButton setToolTip:NSLocalizedString(@"Play mode: Single",nil)];
		break;
	}
}
/************************************************************************************/
- (void) applyPrefs;
{
	NSEnumerator *columnsEnum;
	NSTableColumn *column;
	float textSize;
	
	// set playlist text font size
	if ([[appController preferences] objectForKey:@"SmallPlaylistText"]) {
		if ([[[appController preferences] objectForKey:@"SmallPlaylistText"]
				isEqualToString:@"YES"])
			textSize = kSmallerTextSize;
		else
			textSize = kDefaultTextSize;
	}
	else
		textSize = kDefaultTextSize;
	
	// set row height
	[playListTable setRowHeight:textSize + 4];
	
	// set scroller size
	if ([[playListTable superview] isKindOfClass:[NSScrollView class]]) {
		NSScroller *theScroller = [(NSScrollView *)[playListTable superview] verticalScroller];
		if (textSize == kDefaultTextSize)
			[theScroller setControlSize:NSRegularControlSize];
		else
			[theScroller setControlSize:NSSmallControlSize];
		[(NSScrollView *)[playListTable superview] setVerticalScroller:theScroller];
	}
	
	// set playlist text font size
	columnsEnum = [[playListTable tableColumns] objectEnumerator];
	while (column = [columnsEnum nextObject]) {
		NSCell *theCell = [column dataCell];
		[theCell setFont:[NSFont systemFontOfSize:textSize]];	
		[column setDataCell:theCell];
	}

	[self updateView];
	[playListTable display];
}
/************************************************************************************/
- (void) finishedPlayingItem:(NSDictionary *)playingItem
{
	int theIndex = [self indexOfItem:playingItem];
	if (theIndex < 0)
		return;
	
	switch (myPlayMode) {
	case 0 :								// single item play mode
		theIndex = -1;						// stop playback
		break;
	case 1 :								// continous play mode
		theIndex++;							// move to next track
		if (theIndex >= [self itemCount])	// if it was lats track
			theIndex = -1;					// stop playback
		break;
	case 2 :								// continous repeat mode
		theIndex++;							// move to next track
		if (theIndex >= [self itemCount])	// if it was lats track
			theIndex = 0;					// move it to the first track
		break;
	default :
		theIndex = -1;						// stop playback
		break;
	}
	
	// play the next item if it is set to do so
	if (theIndex >= 0)
		[playerController playItem:[self itemAtIndex:theIndex]];
}
/************************************************************************************
 ACTIONS
 ************************************************************************************/
- (IBAction)displayItemSettings:(id)sender
{
	// if there is no info records for the item ged it first
	if (![[self selectedItem] objectForKey:@"ID_FILENAME"])
		[playerController preflightItem:[self selectedItem]];
	[settingsController displayForItem:[self selectedItem]];
	[settingsButton setEnabled:NO];
}
/************************************************************************************/
- (IBAction)changePlayMode:(id)sender
{
	myPlayMode++;
	if (myPlayMode > 2)
		myPlayMode = 0;
	[self updateView];
}
/************************************************************************************/
- (IBAction)cancelPreflight:(id)sender
{
	[NSApp abortModal];
}

/************************************************************************************
 MISC METHODS
 ************************************************************************************/
/************************************************************************************
 DATA SOURCE METHODS
 ************************************************************************************/
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{	
	return [myData count];
}

/************************************************************************************/
- (id)tableView:(NSTableView *)tableView
		objectValueForTableColumn:(NSTableColumn *)tableColumn
		row:(int)row
{    
	// movie title column
	if ([[tableColumn identifier] isEqualToString:@"movie"]) {
		if ([[myData objectAtIndex:row] objectForKey:@"ItemTitle"])
			return [[myData objectAtIndex:row] objectForKey:@"ItemTitle"];
		else
			return [[[myData objectAtIndex:row]
					objectForKey:@"MovieFile"] lastPathComponent];
	}
	// movie length column
	if ([[tableColumn identifier] isEqualToString:@"time"]) {
		if ([[myData objectAtIndex:row] objectForKey:@"ID_LENGTH"])
			if ([[[myData objectAtIndex:row] objectForKey:@"ID_LENGTH"] intValue] > 0) {
				int seconds = [[[myData objectAtIndex:row]
						objectForKey:@"ID_LENGTH"] intValue];
				return [NSString stringWithFormat:@"%01d:%02d:%02d",
						seconds/3600,(seconds%3600)/60,seconds%60];
			}
			else
				return @"-:--:--";
		else
			return @"-:--:--";
	}
	// movie status Column
	if ([[tableColumn identifier] isEqualToString:@"status"]) {
		if ([myData indexOfObjectIdenticalTo:[playerController playingItem]] == row)
			return statusIcon;
	}
	return nil;
}
/************************************************************************************/
// when a drag-and-drop operation comes through, and a filename is being dropped on the table,
// we need to tell the table where to put the new filename (right at the end of the table).
// This controls the visual feedback to the user on where their drop will go.
- (NSDragOperation)tableView:(NSTableView*)tv 
		validateDrop:(id <NSDraggingInfo>)info
		proposedRow:(int)row
		proposedDropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard *myPasteboard=[info draggingPasteboard];
    NSArray *typeArray=[NSArray
			arrayWithObjects:NSFilenamesPboardType,@"PlaylistSelectionEnumeratorType",nil];
    NSString *availableType;
    NSArray *propertyList;
    int i;
    NSLog(@"validated");
	// check if one of allowed types is avialable in pasteboard
    availableType=[myPasteboard availableTypeFromArray:typeArray];

	if ([availableType isEqualToString:@"PlaylistSelectionEnumeratorType"]) {
		// drag inside the table
		[tv setDropRow:row dropOperation:NSTableViewDropAbove];
		return op;
	}
	if([availableType isEqualToString:NSFilenamesPboardType]) {
		// then get array of filenames
	  NSData* pbData = [myPasteboard dataForType: NSFilenamesPboardType];
	  if (pbData)
	   {
	     propertyList = [NSUnarchiver unarchiveObjectWithData: pbData];
	   }

		for (i=0;i<[propertyList count];i++) {
			// get extension of the path and check if it is not subtitles extension
			if ([appController isExtension:[[propertyList objectAtIndex:i] pathExtension]
					ofType:@"Movie file"] )
//  || [appController isExtension:
// 					[[propertyList objectAtIndex:i] pathExtension] ofType:@"Audio file"])
				break;
		}
		
		if (i < [propertyList count]) {
			// if new movie is dragged then insert it where it is supposed to be
			[tv setDropRow:row dropOperation:NSTableViewDropAbove];
			return op;
		}
		else {
			if (row >= 0 && [myData count] > 0) {
				// if subtitles is dragged then assign it to the movie
				[tv setDropRow:row dropOperation:NSTableViewDropOn];
				return op;
			}
			else
				return NSDragOperationNone;
		}
	}
	return NSDragOperationNone;
}
/************************************************************************************/
// This routine does the actual processing for a drag-and-drop operation on a tableview.
// As the tableview's data source, we get this call when it's time to update our backend data.
- (BOOL)tableView:(NSTableView*)tv
		acceptDrop:(id <NSDraggingInfo>)info
		row:(int)row
		dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard *myPasteboard=[info draggingPasteboard];
    NSArray *propertyList, *typeArray=[NSArray
			arrayWithObjects:NSFilenamesPboardType,@"PlaylistSelectionEnumeratorType",nil];
    NSString *availableType;

    NSLog(@"accepted");
	// check if one of allowed types is avialable in pasteboard
    availableType=[myPasteboard availableTypeFromArray:typeArray];
	// get list of filenames dropped on table
    NSData* pbData = [myPasteboard dataForType: NSFilenamesPboardType];
    if (pbData)
      {
	propertyList = [NSUnarchiver unarchiveObjectWithData: pbData];
      }
    	// reset selection
	[tv deselectAll:nil];
	
	if ([availableType isEqualToString:@"PlaylistSelectionEnumeratorType"]) {
		NSMutableArray *itemsStore = [NSMutableArray array];
		int i, removeIndex, insertIndex = row;
		
		// store dragged objects
		for (i=0;i<[propertyList count];i++) {
			[itemsStore addObject:[myData
					objectAtIndex:[[propertyList objectAtIndex:i] intValue]]];
		}
		
		// remove selected objects
		for (i=0;i<[itemsStore count];i++) {
			removeIndex = [myData indexOfObjectIdenticalTo:[itemsStore objectAtIndex:i]];
			// remove object
			[myData removeObjectAtIndex:removeIndex];
			// deal with poibility that insertion point might change too
			if (removeIndex < insertIndex)	// if insertion point was affected by remove
				insertIndex--;				// then decrement it
		}
		// isert objects back to the list
		for (i=0;i<[itemsStore count];i++) {
			// insert object
			[myData insertObject:[itemsStore objectAtIndex:i] atIndex:insertIndex];
			// manage selection
			if ([tv selectedRow] == -1)
				[tv selectRow:insertIndex byExtendingSelection:NO];
			else
				[tv selectRow:insertIndex byExtendingSelection:YES];
			insertIndex++;
		}
	}
	if([availableType isEqualToString:NSFilenamesPboardType]) {
		int i, insertIndex = row;
		// divide dragged files to arrays by its type
		NSArray *movieList = [propertyList pathsMatchingExtensions:
					[appController typeExtensionsForName:@"Movie file"]];
		NSArray *subtitlesList = [propertyList pathsMatchingExtensions:
					[appController typeExtensionsForName:@"Subtitles file"]];
		NSArray *audioList = [propertyList pathsMatchingExtensions:
					[appController typeExtensionsForName:@"Audio file"]];

		if (op == NSTableViewDropOn && [subtitlesList count] > 0)
			// if only subtitles were dropped, take only first file and add it to the row
			[[myData objectAtIndex:row] setObject:[subtitlesList objectAtIndex:0]
					forKey:@"SubtitlesFile"];
		else {
			// else
			NSModalSession progressSession = 0;
			NSArray *insertList;
			// we prefer movies before audio
			if ([movieList count] > 0)
				insertList = movieList;
			else
				insertList = audioList;
			// if there are more items than 3 then display progress for it
			if ([insertList count] > 3) {
				[progressBar setMaxValue:[insertList count]];
				[progressBar setDoubleValue:0];
				[filenameBox setStringValue:@""];
				progressSession = [NSApp
						beginModalSessionForWindow:preflightPanel];
			}
			// add objects to the playlist
			for (i=0;i<[insertList count];i++) {
				NSMutableDictionary *myItem = [NSMutableDictionary dictionary];
				if ([movieList count] > 0) {
					// if movies are dropped
					[myItem setObject:[movieList objectAtIndex:i] forKey:@"MovieFile"];
					if (i < [subtitlesList count])
						[myItem setObject:[subtitlesList objectAtIndex:i] forKey:@"SubtitlesFile"];
					if (i < [audioList count])
						[myItem setObject:[audioList objectAtIndex:i] forKey:@"AudioFile"];
				}
				else
					[myItem setObject:[audioList objectAtIndex:i] forKey:@"MovieFile"];
				
				// if progress was created for this
				if (progressSession != 0) {
					if ([NSApp runModalSession:progressSession] !=
							NSRunContinuesResponse)
						break;
					[filenameBox setStringValue:[[insertList objectAtIndex:i]
							lastPathComponent]];
					[progressBar setDoubleValue:(i+1)];
				}
				// preflight the item
				[playerController preflightItem:myItem];
				// insert item in to playlist
				[myData insertObject:myItem atIndex:insertIndex];
				// manage selection
				if ([tv selectedRow] == -1)
					[tv selectRow:insertIndex byExtendingSelection:NO];
				else
					[tv selectRow:insertIndex byExtendingSelection:YES];
				insertIndex++;
			}
			// if progress was created then release it
			if (progressSession != 0) {
				[NSApp endModalSession:progressSession];
				[preflightPanel orderOut:nil];
			}
		}
    }
	[self updateView];
	return YES;
}
/************************************************************************************/
// handle drags inside the table
- (BOOL)tableView:(NSTableView *)tableView
		writeRows:(NSArray*)rows
		toPasteboard:(NSPasteboard*)pasteboard
{
    NSLog(@"write !!!");
  // if anything selected
	if ([tableView numberOfSelectedRows] == 0)
		return NO;

	// set list of playlist rows that are involved in drag operation
	rows = [[tableView selectedRowEnumerator] allObjects];

	pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	// prepare pasteboard
	[pasteboard declareTypes:[NSArray arrayWithObject:@"PlaylistSelectionEnumeratorType"] owner:nil];
	
	// put data to the pasteboard
	if ([pasteboard setPropertyList:[[tableView selectedRowEnumerator] allObjects]
				forType:@"PlaylistSelectionEnumeratorType"])
		return YES;
	return NO;
}

/************************************************************************************
 DELEGATE METHODS
 ************************************************************************************/
- (BOOL) validateMenuItem:(NSMenuItem *)aMenuItem
{
	if ([[aMenuItem title] isEqualToString:NSLocalizedString(@"Info...",nil)]) {
		if ([playListTable numberOfSelectedRows] == 1 && ![settingsController isVisible])
			return YES;
	}
	return NO;
}
/************************************************************************************/
- (IBAction)doubleClick:(id)sender
{
	[playerController playItem:[myData objectAtIndex:[playListTable clickedRow]]];
}
/************************************************************************************/
// Stop the table's rows from being editable when we double-click on them
- (BOOL)tableView:(NSTableView *)tableView
		shouldEditTableColumn:(NSTableColumn *)tableColumn 
		row:(int)row
{    
	return NO;
}
/************************************************************************************/
// disable cell background
- (void)tableView:(NSTableView *)aTableView
		willDisplayCell:(id)aCell
		forTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex
{
	if ([aCell isKindOfClass:[NSTextFieldCell class]])
		[aCell setDrawsBackground:NO];
}
/************************************************************************************
 NOTIFICATION HANDLERS
 ************************************************************************************/
- (void) appFinishedLaunching
{
//	[self applyPrefs];
}
/************************************************************************************/
- (void) appShouldTerminate
{
	// save values to prefs
	[[appController preferences] setObject:[NSNumber numberWithInt:myPlayMode]
			forKey:@"PlayMode"];
}
/************************************************************************************/
- (void)appTerminating
{
	// save playlist to prefs
  //Change that for GNUStep
#ifdef __APPLE__
  CFPreferencesSetAppValue((CFStringRef)@"PlayList", (CFPropertyListRef)myData,
			   kCFPreferencesCurrentApplication);

  CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
#else
  NSUserDefaults *preferences = [appController preferences];
  [preferences setObject:myData forKey:@"PlayList"];
  [preferences synchronize];
#endif
	// release data
	[myData release];
	[statusIcon release];
	[playMode0Image release];
	[playMode1Image release];
	[playMode2Image release];
 }

@end
