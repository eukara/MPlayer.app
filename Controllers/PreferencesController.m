/*
 *  PreferencesController.m
 *  MPlayer OS X
 *
 *  Created by Jan Volf
 *	<javol@seznam.cz>
 *  Copyright (c) 2003 Jan Volf. All rights reserved.
 */

#import "PreferencesController.h"

// other controllers
#import "AppController.h"
#import "PlayListCtrllr.h"
#import "PlayerCtrllr.h"

@implementation PreferencesController

/************************************************************************************
 MISC
 ************************************************************************************/
- (void) reloadValues
{
	NSUserDefaults *thePrefs = [appController preferences];
	
	// create fonts menu
	[self initFontMenu];
	
	// playlist text size
	if ([thePrefs objectForKey:@"SmallPlaylistText"]) {
		if ([[thePrefs objectForKey:@"SmallPlaylistText"] isEqualToString:@"YES"])
			[smallTextButton setState:NSOnState];
		else
			[smallTextButton setState:NSOffState];
	}
	else
		[smallTextButton setState:NSOffState];
	
	// remember position option
	if ([thePrefs objectForKey:@"RememberPosition"]) {
		if ([[thePrefs objectForKey:@"RememberPosition"] isEqualToString:@"YES"])
			[rememberButton setState:NSOnState];
		else
			[rememberButton setState:NSOffState];
	}
	else
		[rememberButton setState:NSOffState];
	
	// video size
	if ([thePrefs objectForKey:@"VideoFrameSize"])
		[videoSizeMenu selectItemAtIndex:
				[[thePrefs objectForKey:@"VideoFrameSize"] intValue]];
	else
		[videoSizeMenu selectItemWithTitle:NSLocalizedString(@"Normal",nil)];
	
	// video width
	if ([thePrefs objectForKey:@"VideoFrameWidth"])
		[videoWidthButton setIntValue:[[thePrefs
				objectForKey:@"VideoFrameWidth"] unsignedIntValue]];
	else
		[videoWidthButton selectItemAtIndex:0];
	
	// video aspect
	if ([thePrefs objectForKey:@"VideoAspectRatio"])
		[videoAspectMenu selectItemAtIndex:
				[[thePrefs objectForKey:@"VideoAspectRatio"] intValue]];
	else
		[videoAspectMenu selectItemWithTitle:NSLocalizedString(@"default",nil)];
	
	// fullscreen by default
	if ([thePrefs objectForKey:@"FullscreenByDefault"]) {
		if ([[thePrefs objectForKey:@"FullscreenByDefault"] isEqualToString:@"YES"])
			[defaultFullscreenButton setState:NSOnState];
		else
			[defaultFullscreenButton setState:NSOffState];
	}
	else
		[defaultFullscreenButton setState:NSOffState];
	
	// drop frames
	if ([thePrefs objectForKey:@"DropFrames"]) {
		if ([[thePrefs objectForKey:@"DropFrames"] isEqualToString:@"YES"])
			[dropFramesButton setState:NSOnState];
		else
			[dropFramesButton setState:NSOffState];
	}
	else
		[dropFramesButton setState:NSOffState];
		
		////BETA CODE////
		// rootwin
	if ([thePrefs objectForKey:@"Rootwin"]) {
		if ([[thePrefs objectForKey:@"Rootwin"] isEqualToString:@"YES"])
			[rootwinButton setState:NSOnState];
		else
			[rootwinButton setState:NSOffState];
	}
	else
		[rootwinButton setState:NSOffState];
		
		// tile
	if ([thePrefs objectForKey:@"Tile"]) {
		if ([[thePrefs objectForKey:@"Tile"] isEqualToString:@"YES"])
			[tileButton setState:NSOnState];
		else
			[tileButton setState:NSOffState];
	}
	else
		[tileButton setState:NSOffState];
		
		
		// nosound
	if ([thePrefs objectForKey:@"nosound"]) {
		if ([[thePrefs objectForKey:@"nosound"] isEqualToString:@"YES"])
			[nosoundbutton setState:NSOnState];
		else
			[nosoundbutton setState:NSOffState];
	}
	else
		[nosoundbutton setState:NSOffState];
				
		// second monitor
	if ([thePrefs objectForKey:@"SecondMonitor"]) {
		if ([[thePrefs objectForKey:@"SecondMonitor"] isEqualToString:@"YES"])
			[secMonitorbutton setState:NSOnState];
		else
			[secMonitorbutton setState:NSOffState];
	}
	else
		[secMonitorbutton setState:NSOffState];
		
		//postprocesing
	if ([thePrefs objectForKey:@"Postprocesing"]) {
		if ([[thePrefs objectForKey:@"Postprocesing"] isEqualToString:@"YES"])
			[Postprocesingbutton setState:NSOnState];
		else
			[Postprocesingbutton setState:NSOffState];
	}
	else
		[Postprocesingbutton setState:NSOffState];


	
	// subtitles font
	if ([thePrefs objectForKey:@"SubtitlesFontPath"]) {
		[subFontMenu selectItemAtIndex:[subFontMenu indexOfItemWithRepresentedObject:
				[thePrefs objectForKey:@"SubtitlesFontPath"]]];
		if ([subFontMenu indexOfSelectedItem] < 0)
			[subFontMenu selectItemAtIndex:0];
	}
	else
		[subFontMenu selectItemAtIndex:0];
		
	// subtitles encoding
	if ([thePrefs objectForKey:@"SubtitlesEncoding"]) {
		[subEncodingMenu selectItemWithTitle:[thePrefs objectForKey:@"SubtitlesEncoding"]];
		if ([subEncodingMenu indexOfSelectedItem] < 0)
			[subEncodingMenu selectItemAtIndex:0];
		}
	else
		[subEncodingMenu selectItemAtIndex:0];
	
	// subtitles size
	if ([thePrefs objectForKey:@"SubtitlesSize"])
		[subSizeMenu selectItemAtIndex:
				[[thePrefs objectForKey:@"SubtitlesSize"] intValue]];
	else
		[subSizeMenu selectItemWithTitle:NSLocalizedString(@"normal",nil)];
		

	// cache setings
	if ([thePrefs objectForKey:@"CacheSize"]) {
		if ([[thePrefs objectForKey:@"CacheSize"] unsignedIntValue] > 1) {
			[enableCacheButton setState:NSOnState];
			[cacheSizeSlider setIntValue:
					[[thePrefs objectForKey:@"CacheSize"] unsignedIntValue]];
			[cacheSizeBox setIntValue:
					[[thePrefs objectForKey:@"CacheSize"] unsignedIntValue]];
		}
		else
			[enableCacheButton setState:NSOffState];
	}
	else
		[enableCacheButton setState:NSOffState];
	
	// additional params box
	if ([thePrefs objectForKey:@"EnableAdditionalParams"]) {
		if ([[thePrefs objectForKey:@"EnableAdditionalParams"] isEqualToString:@"YES"])
			[addParamsButton setState:NSOnState];
		else
			[addParamsButton setState:NSOffState];
	}
	else
		[dropFramesButton setState:NSOffState];
	// additional
	[addParamsBox removeAllItems];
	[addParamsBox setHasVerticalScroller:NO];
	if ([thePrefs objectForKey:@"AdditionalParams"]) {
		if ([[thePrefs objectForKey:@"AdditionalParams"] isKindOfClass:[NSString class]])
			[addParamsBox addItemWithObjectValue:[thePrefs objectForKey:@"AdditionalParams"]];
		else
			[addParamsBox addItemsWithObjectValues:[thePrefs objectForKey:@"AdditionalParams"]];
		[addParamsBox selectItemAtIndex:0];
		[addParamsBox setHasVerticalScroller:NO];
		[addParamsBox setNumberOfVisibleItems:[addParamsBox numberOfItems]];
	}
	
	[self enableControls:nil];
}
/************************************************************************************/
- (void) initFontMenu
{
	NSArray *paths;
	NSEnumerator *pathsEnum;
	NSString *path;

	// clear menu
	[subFontMenu removeAllItems];
	
	// add first item - none and separator
	[subFontMenu addItemWithTitle:NSLocalizedString(@"none",nil)];
	[[subFontMenu lastItem] setTag:0];
	[[subFontMenu menu] addItem:[NSMenuItem separatorItem]];
	
	// get paths to all files and dirs
	paths = [[NSFileManager defaultManager] subpathsAtPath:
			[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Fonts"]];

	// add truetype fonts (tag 1)
	pathsEnum = [paths objectEnumerator];
	while (path = [pathsEnum nextObject]) {
		if ([[path pathExtension] caseInsensitiveCompare:@"ttf"] == NSOrderedSame) {
			[subFontMenu addItemWithTitle:[[path lastPathComponent]
					stringByDeletingPathExtension]];
			[[subFontMenu lastItem] setTag:1];
			[[subFontMenu lastItem] setRepresentedObject:path];
		}
	}
	// if last item is not separator then add it
	if (![[subFontMenu lastItem] isSeparatorItem])
		[[subFontMenu menu] addItem:[NSMenuItem separatorItem]];

	// add pre-rendered fonts (tag 2)
	pathsEnum = [paths objectEnumerator];
	while (path = [pathsEnum nextObject]) {
		if ([[path lastPathComponent] caseInsensitiveCompare:@"font.desc"] == NSOrderedSame) {
			[subFontMenu addItemWithTitle:[path stringByDeletingLastPathComponent]];
			[[subFontMenu lastItem] setTag:2];
			[[subFontMenu lastItem] setRepresentedObject:path];
		}
	}

	// remove separator if it is last item
	if ([[subFontMenu lastItem] isSeparatorItem])
		[subFontMenu removeItemAtIndex:[subFontMenu numberOfItems]-1];
}
/************************************************************************************
 ACTIONS
 ************************************************************************************/
- (IBAction)displayPreferences:(id)sender
{
	// init values
	[self reloadValues];
			
	[prefsPanel makeKeyAndOrderFront:self];
}
/************************************************************************************/
- (IBAction)applyPrefs:(id)sender
{
	NSUserDefaults *thePrefs = [appController preferences];
	
	// playlist text size
	if ([smallTextButton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"SmallPlaylistText"];
	else
		[thePrefs setObject:@"NO" forKey:@"SmallPlaylistText"];
	
	// remember position option
	if ([rememberButton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"RememberPosition"];
	else
		[thePrefs setObject:@"NO" forKey:@"RememberPosition"];
	
	// video size
	[thePrefs setObject:[NSNumber numberWithInt:[videoSizeMenu indexOfSelectedItem]]
			forKey:@"VideoFrameSize"];
	
	// video width
	[thePrefs setObject:[NSNumber numberWithInt:[videoWidthButton intValue]]
			forKey:@"VideoFrameWidth"];
	
	// video aspect
	[thePrefs setObject:[NSNumber numberWithInt:[videoAspectMenu indexOfSelectedItem]]
			forKey:@"VideoAspectRatio"];
	
	// fullscreen by default
	if ([defaultFullscreenButton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"FullscreenByDefault"];
	else
		[thePrefs setObject:@"NO" forKey:@"FullscreenByDefault"];
		
		///BETA CODE///
		// rootwin
	if ([rootwinButton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"Rootwin"];
	else
		[thePrefs setObject:@"NO" forKey:@"Rootwin"];
	
		// Tile
	if ([tileButton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"Tile"];
	else
		[thePrefs setObject:@"NO" forKey:@"Tile"];
	   
		//nosound
	if ([nosoundbutton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"nosound"];
	else
		[thePrefs setObject:@"NO" forKey:@"nosound"];
		
		//second monitor
	if ([secMonitorbutton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"SecondMonitor"];
	else
		[thePrefs setObject:@"NO" forKey:@"SecondMonitor"];
			
		//postprocesing
	if ([Postprocesingbutton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"Postprocesing"];
	else
		[thePrefs setObject:@"NO" forKey:@"Postprocesing"];
	
	// drop frames
	if ([dropFramesButton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"DropFrames"];
	else
		[thePrefs setObject:@"NO" forKey:@"DropFrames"];
	
	// subtitles font
	if ([subFontMenu indexOfSelectedItem] <= 0)
		[thePrefs removeObjectForKey:@"SubtitlesFontPath"];
	else
		[thePrefs setObject:[[subFontMenu selectedItem] representedObject]
				forKey:@"SubtitlesFontPath"];

	// subtitles encoding
	[thePrefs setObject:[subEncodingMenu titleOfSelectedItem]
			forKey:@"SubtitlesEncoding"];
	
	// subtitles size
	[thePrefs setObject:[NSNumber numberWithInt:[subSizeMenu indexOfSelectedItem]]
			forKey:@"SubtitlesSize"];
	
	// cache size
	if ([enableCacheButton state] == NSOnState)
		[thePrefs setObject:[NSNumber numberWithInt:[cacheSizeSlider intValue]]
				forKey:@"CacheSize"];
	else
		[thePrefs setObject:[NSNumber numberWithInt:0] forKey:@"CacheSize"];
	
	// enable additional params
	if ([addParamsButton state] == NSOnState)
		[thePrefs setObject:@"YES" forKey:@"EnableAdditionalParams"];
	else
		[thePrefs setObject:@"NO" forKey:@"EnableAdditionalParams"];
	
	// additional params
	if (![[[addParamsBox stringValue] stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
		// get array of parameters
		NSMutableArray *theArray = [NSMutableArray
				arrayWithArray:[addParamsBox objectValues]];
		if ([addParamsBox indexOfItemWithObjectValue:
				[addParamsBox stringValue]] != NSNotFound) {
			// if the entered param exist in the history then remove it from array
			[theArray removeObjectAtIndex:[addParamsBox
					indexOfItemWithObjectValue: [addParamsBox stringValue]]];
		}
		// add parameter at the top of the array
		[theArray insertObject:[addParamsBox stringValue] atIndex:0];
		if ([theArray count] > 10)	// remove last object if there is too much objects
			[theArray removeLastObject];
		// save array to the prefs
		[thePrefs setObject:theArray forKey:@"AdditionalParams"];
	}
	
	[playerController applyPrefs];
	if ([playerController changesRequireRestart]) {
		NSBeginAlertSheet(
				NSLocalizedString(@"Do you want to restart playback?",nil),
				NSLocalizedString(@"OK",nil),
				NSLocalizedString(@"Later",nil), nil, prefsPanel, self,
				@selector(sheetDidEnd:returnCode:contextInfo:), nil, nil,
				NSLocalizedString(@"Some of the changes requires player to restart playback that might take a while.",nil));
	}
	else {
		[prefsPanel orderOut:nil];
		[playListController applyPrefs];
	}
}
/************************************************************************************/
- (IBAction)cancelPrefs:(id)sender
{
	[prefsPanel orderOut:nil];
}
/************************************************************************************/
- (IBAction)prefsChanged:(id)sender
{
}
/************************************************************************************/
- (IBAction)enableControls:(id)sender
{
	// video width box
	if ([[videoSizeMenu titleOfSelectedItem]
			isEqualToString:NSLocalizedString(@"Fit width",nil)])
		[videoWidthButton setEnabled:YES];
	else
		[videoWidthButton setEnabled:NO];
	
	// cache size settings
	if ([enableCacheButton state] == NSOnState) {
		[cacheSizeSlider setEnabled:YES];
		[cacheSizeBox setEnabled:YES];
	}
	else {
		[cacheSizeSlider setEnabled:NO];
		[cacheSizeBox setEnabled:NO];
	}
	
	// enable subtitles settings deppending on selected font
	switch ([[subFontMenu selectedItem] tag]) {
	case 1 : // truetype font
		[subSizeMenu setEnabled:YES];
		[subEncodingMenu setEnabled:YES];
		break;
	default : // pre-rendered fonts and none
		[subSizeMenu setEnabled:NO];
		[subEncodingMenu setEnabled:NO];
		break;
	}
	

	// enable additionals params box
	if ([addParamsButton state] == NSOnState)
		[addParamsBox setEnabled:YES];
	else
		[addParamsBox setEnabled:NO];

	// if initiated by control then let the action continue
	if (sender)
		[self prefsChanged:sender];
}
/************************************************************************************/
- (IBAction)cacheSizeChanged:(id)sender
{
	[cacheSizeBox setStringValue:[NSString stringWithFormat:@"%d MB",[sender intValue]]];
}
/************************************************************************************
 DELEGATE METHODS
 ************************************************************************************/
- (void) sheetDidEnd:(NSWindow *)sheet
		returnCode:(int)returnCode
		contextInfo:(void *)contextInfo
{
	[prefsPanel orderOut:nil];

	if (returnCode == NSAlertDefaultReturn)
		[playerController applyChangesWithRestart:YES];
	else
		[playerController applyChangesWithRestart:NO];
	
	[playListController applyPrefs];	
}

@end
