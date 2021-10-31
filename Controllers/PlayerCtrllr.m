/*
 *  PlayerCtrllr.m
 *  MPlayer OS X
 *
 *  Created by Jan Volf
 *	<javol@seznam.cz>
 *  Copyright (c) 2003 Jan Volf. All rights reserved.
 */

#import "PlayerCtrllr.h"

// other conreollers
#import "AppController.h"
#import "PlayListCtrllr.h"

// custom classes
#import "ScrubbingBar.h"

@implementation PlayerCtrllr

/************************************************************************************/
-(void)awakeFromNib
{
	NSUserDefaults *prefs = [appController preferences];
	unichar myChar;
	saveTime = YES;
	fullscreenStatus = NO;	// by default we play in window
	

	// init player
	myPlayer = [[MplayerInterface alloc] initWithPathToPlayer:
			[[[NSBundle mainBundle] resourcePath]
			stringByAppendingPathComponent:@"mplayer.app/Contents/MacOS/mplayer"]];
/*	myPlayer = [[MplayerInterface alloc] initWithPathToPlayer:
			[[NSBundle mainBundle] pathForResource:@"mplayer" ofType:nil]];
*/	// register for mplayer playback start
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(playbackStarted)
			name: @"MIInfoReadyNotification"
			object:myPlayer];
	// register for mplayer status update
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(statusUpdate:)
			name: @"MIStateUpdatedNotification"
			object:myPlayer];

	// register for notification on clicking progress bar
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(progresBarClicked:)
			name: @"SBBarClickedNotification"
			object:progressBar];

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
	// register for app pre termination notification
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(appShouldTerminate)
			name: @"ApplicationShouldTerminateNotification"
			object:NSApp];
	
	// load images
	playImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
							pathForResource:@"play"
							ofType:@"png"]];
	pauseImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
							pathForResource:@"pause"
							ofType:@"png"]];
	// load mini images
	playImageMini = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
							pathForResource:@"play_mini"
							ofType:@"png"]];
	pauseImageMini = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle]
							pathForResource:@"pause_mini"
							ofType:@"png"]];
	
	// set up prograss bar
#ifdef __COCOA__
	[progressBar setStyle:NSScrubbingBarEmptyStyle];
#endif
	[progressBar setIndeterminate:NO];
	
	// set up controls key equivalents
	[playMenuItem setKeyEquivalent:@"space"];
	myChar = NSLeftArrowFunctionKey;
	[seekBackMenuItem setKeyEquivalent:
			[NSString stringWithCharacters:(const unichar *) &myChar length:1]];
	[seekBackMenuItem setKeyEquivalentModifierMask:0];
	myChar = NSRightArrowFunctionKey;
	[seekFwdMenuItem setKeyEquivalent:
			[NSString stringWithCharacters:(const unichar *) &myChar length:1]];
	[seekFwdMenuItem setKeyEquivalentModifierMask:0];
	
	// set volume to the last used value
	if ([prefs objectForKey:@"LastAudioVolume"]) {
		[volumeSlider setDoubleValue:[[prefs objectForKey:@"LastAudioVolume"] doubleValue]];
		[volumeSliderMini setDoubleValue:[[prefs objectForKey:@"LastAudioVolume"] doubleValue]];
		[myPlayer setVolume:[[prefs objectForKey:@"LastAudioVolume"] intValue]];
	}
	else {
		[volumeSlider setDoubleValue:100];
		[volumeSliderMini setDoubleValue:100];
		[myPlayer setVolume:100];
	}
	
	// display player window
	if ([prefs objectForKey:@"MinimizedWindow"]) {
		if ([[prefs objectForKey:@"MinimizedWindow"] isEqualToString:@"YES"])
			[self displayWindow:YES];
		else
			[self displayWindow:NO];
	}
	else
		[self displayWindow:NO];

	// apply prefs to player
	[self applyPrefs];

}

/************************************************************************************
 INTERFACE
 ************************************************************************************/
- (void) displayWindow: (BOOL)minimized
{
	if (minimized) {
		[miniWindow makeKeyAndOrderFront:nil];
	}
	else {
		[mainWindow makeKeyAndOrderFront:nil];
	}
}
/************************************************************************************/
- (BOOL)preflightItem:(NSMutableDictionary *)anItem
{
	BOOL result;
	MplayerInterface *preflightTask = [MplayerInterface alloc];
	NSDictionary *theInfo;
	// init preflight task with path to player
	[preflightTask initWithPathToPlayer:[[NSBundle mainBundle] 
			pathForResource:@"preflighter" ofType:@""]];
	// set movie
	[preflightTask setMovieFile:[anItem objectForKey:@"MovieFile"]];
	// perform preflight
	theInfo = [preflightTask loadInfo];
	
	if (theInfo) {
		[anItem addEntriesFromDictionary:theInfo];
		result = YES;
	}
	else
		result = NO;
	// release the task
	[preflightTask autorelease];

	return result;
}

/************************************************************************************/
- (void)playItem:(NSMutableDictionary *)anItem
{
	NSString *aPath;
	BOOL loadInfo;
	
	// stops mplayer if it is running
	if ([myPlayer isRunning]) {
		saveTime = NO;		// don't save time
		[myPlayer stop];
		[playListController updateView];
	}
	
	// prepare player
	// set movie file
	aPath = [anItem objectForKey:@"MovieFile"];
	if (aPath) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:aPath] ||
				[NSURL URLWithString:aPath]) // if the file exist or it is an URL
			[myPlayer setMovieFile:aPath];
		else {
			NSRunAlertPanel(NSLocalizedString(@"Error",nil), [NSString stringWithFormat:
					NSLocalizedString(@"File %@ could not be found.",nil), aPath],
					NSLocalizedString(@"OK",nil),nil,nil);
			return;
		}
	}
	else
		return;

	// backup item that is playing
	myPlayingItem = [anItem retain];
	
	// apply item settings
	[self applySettings];

	// set video size for case it is set to fit screen so we have to compare
	// screen size with movie size
	[self setMovieSize];

	// set the start of playback
	if ([myPlayingItem objectForKey:@"LastSeconds"])
		[myPlayer seek:[[myPlayingItem objectForKey:@"LastSeconds"] floatValue]
				mode:MIAbsoluteSeekingMode];
	else
		[myPlayer seek:0 mode:MIAbsoluteSeekingMode];

	// load info before playback only if it was not previously loaded
	if ([myPlayingItem objectForKey:@"ID_FILENAME"])
		loadInfo = NO;
	else
		loadInfo = YES;

	[myPlayer loadInfoBeforePlayback:loadInfo];

	// start playback
	[myPlayer play];
	
	// its enough to load info only once so disable it
	if (loadInfo)
		[myPlayer loadInfoBeforePlayback:NO];
}

/************************************************************************************/
- (NSMutableDictionary *) playingItem
{
	if ([myPlayer isRunning])
		return [[myPlayingItem retain] autorelease]; // get it's own retention
	else
		return nil;
}

/************************************************************************************/
- (BOOL) isRunning
{	return [myPlayer isRunning];		}

/************************************************************************************/
- (BOOL) isPlaying
{	
	if ([myPlayer status] != kStopped && [myPlayer status] != kFinished)
		return YES;
	else
		return NO;
}

/************************************************************************************/
// applay values from preferences to player controller
- (void) applyPrefs;
{
	NSUserDefaults *preferences = [appController preferences];
	
	if ([preferences objectForKey:@"SubtitlesFontPath"]) {
	// if subtitles font is specified
		// set the font
		[myPlayer setFontFile:[[[[NSBundle mainBundle] resourcePath]
			stringByAppendingPathComponent:@"Fonts"] 
			stringByAppendingPathComponent:[preferences objectForKey:@"SubtitlesFontPath"]]];
		
		if ([[[preferences objectForKey:@"SubtitlesFontPath"] lastPathComponent]
				caseInsensitiveCompare:@"font.desc"] == NSOrderedSame) {
		// if prerendered font selected
			[myPlayer setSubtitlesScale:0];
		}
		else {
		// if true type font selected
			// set subtitles size
			if ([preferences objectForKey:@"SubtitlesSize"]) {
				switch ([[preferences objectForKey:@"SubtitlesSize"] intValue]) {
				case 0 : 		// smaller
					[myPlayer setSubtitlesScale:3];
					break;
				case 1 : 		// normal
					[myPlayer setSubtitlesScale:4];
					break;
				case 2 :		// larger
					[myPlayer setSubtitlesScale:5];
					break;
				case 3 :		// largest
					[myPlayer setSubtitlesScale:7];
					break;
				default :
					[myPlayer setSubtitlesScale:0];
					break;
				}
			}
		}
	}
	else {
	// if ther's no subtitles font
		[myPlayer setFontFile:nil];
		[myPlayer setSubtitlesScale:0];
	}

	// set encoding
	[self setSubtitlesEncoding];
	
	// set video size
	[self setMovieSize];
	
	// set aspect ratio
	if ([preferences objectForKey:@"VideoAspectRatio"]) {
		switch ([[preferences objectForKey:@"VideoAspectRatio"] intValue]) {
		case 1 :
			[myPlayer setAspectRatio:1.3333];		// 4:3
			break;
		case 2 :
			[myPlayer setAspectRatio:1.7777];		// 16:9
			break;
		default :
			[myPlayer setAspectRatio:0];
			break;
		}
	}
	else
		[myPlayer setAspectRatio:0];
	
	// default fullscreen
	if ([preferences objectForKey:@"FullscreenByDefault"]) {
		if ([[preferences objectForKey:@"FullscreenByDefault"] isEqualToString:@"YES"])
			[myPlayer setFullscreen:YES];
		else
			[myPlayer setFullscreen:NO];
	}
	else
		[myPlayer setFullscreen:NO];
		
	////BETA CODE////	
		// rootwin
	if ([preferences objectForKey:@"Rootwin"]) {
		if ([[preferences objectForKey:@"Rootwin"] isEqualToString:@"YES"])
			[myPlayer setRootwin:YES];
		else
			[myPlayer setRootwin:NO];
	}
	else
		[myPlayer setRootwin:NO];	
		
		// tile
	if ([preferences objectForKey:@"Tile"]) {
		if ([[preferences objectForKey:@"Tile"] isEqualToString:@"YES"])
			[myPlayer setTile:YES];
		else
			[myPlayer setTile:NO];
	}
	else
		[myPlayer setTile:NO];	
	
			//nosund
	if ([preferences objectForKey:@"nosound"]) {
		if ([[preferences objectForKey:@"nosound"] isEqualToString:@"YES"])
			[myPlayer setnosound:YES];
		else
			[myPlayer setnosound:NO];
	}
	else
		[myPlayer setnosound:NO];	
			//secondmonitor
	if ([preferences objectForKey:@"SecondMonitor"]) {
		if ([[preferences objectForKey:@"SecondMonitor"] isEqualToString:@"YES"])
			[myPlayer setSecondMonitor:YES];
		else
			[myPlayer setSecondMonitor:NO];
	}
	else
		[myPlayer setSecondMonitor:NO];	
		
		//postprocesing
	if ([preferences objectForKey:@"Postprocesing"]) {
		if ([[preferences objectForKey:@"Postprocesing"] isEqualToString:@"YES"])
			[myPlayer setPostprocesing:YES];
		else
			[myPlayer setPostprocesing:NO];
	}
	else
		[myPlayer setPostprocesing:NO];	
	
	// drop frames
	if ([preferences objectForKey:@"DropFrames"]) {
		if ([[preferences objectForKey:@"DropFrames"] isEqualToString:@"YES"])
			[myPlayer setDropFrames:YES];
		else
			[myPlayer setDropFrames:NO];
	}
	else
		[myPlayer setDropFrames:NO];
	
	// setting cache
	if ([preferences objectForKey:@"CacheSize"]) {
		[myPlayer setCacheSize:
				([[preferences objectForKey:@"CacheSize"] unsignedIntValue] * 1024)];			
	}
	
	// additional params
	if ([preferences objectForKey:@"EnableAdditionalParams"])
		if ([[preferences objectForKey:@"EnableAdditionalParams"] isEqualToString:@"YES"]
				&& [preferences objectForKey:@"AdditionalParams"]) {
			[myPlayer setAdditionalParams:
					[[[preferences objectForKey:@"AdditionalParams"] objectAtIndex:0]
							componentsSeparatedByString:@" "]];
		}
		else
			[myPlayer setAdditionalParams:nil];
	else
		[myPlayer setAdditionalParams:nil];
}
/************************************************************************************/
- (void) applySettings
{
	NSString *aPath;
	
	// set audio file	
	aPath = [myPlayingItem objectForKey:@"AudioFile"];
	if (aPath) {
		if (![[NSFileManager defaultManager] fileExistsAtPath:aPath])
			NSRunAlertPanel(NSLocalizedString(@"Error",nil), [NSString stringWithFormat:
					NSLocalizedString(@"File %@ could not be found.",nil), aPath],
					NSLocalizedString(@"OK",nil),nil,nil);
		else
			[myPlayer setAudioFile:aPath];
	}
	else
		[myPlayer setAudioFile:nil];
	
		
				
//	// set audioexport BETA
//	aPath = [myPlayingItem objectForKey:@"AudioExportFile"];
//	if (aPath) {
//		if (![[NSFileManager defaultManager] fileExistsAtPath:aPath])
//			NSRunAlertPanel(NSLocalizedString(@"Error",nil), [NSString stringWithFormat:
//					NSLocalizedString(@"Audio file saving enabled",nil), aPath],
//					NSLocalizedString(@"OK",nil),nil,nil);
//		else
//			[myPlayer setAudioExportFile:nil];
//	}
//	else
//		[myPlayer setAudioExportFile:nil];
	
	// set subtitles file
	aPath = [myPlayingItem objectForKey:@"SubtitlesFile"];
	if (aPath) {
		if (![[NSFileManager defaultManager] fileExistsAtPath:aPath])
			NSRunAlertPanel(NSLocalizedString(@"Error",nil), [NSString stringWithFormat:
					NSLocalizedString(@"File %@ could not be found.",nil), aPath],
					NSLocalizedString(@"OK",nil),nil,nil);
		else
			[myPlayer setSubtitlesFile:aPath];
	}
	else
		[myPlayer setSubtitlesFile:nil];
	
	// set to rebuild index
	if ([myPlayingItem objectForKey:@"RebuildIndex"]) {
		if ([[myPlayingItem objectForKey:@"RebuildIndex"] isEqualToString:@"YES"])
			[myPlayer setRebuildIndex:YES];
		else
			[myPlayer setRebuildIndex:NO];
	}
	else
		[myPlayer setRebuildIndex:NO];

	// set subtitles encoding only if not default
	if ([myPlayingItem objectForKey:@"SubtitlesEncoding"])
		[self setSubtitlesEncoding];
	else
		[myPlayer setSubtitlesEncoding:nil];
	
	// set status box
	if ([myPlayingItem objectForKey:@"ItemTitle"]) {
		[titleBox setStringValue:[myPlayingItem objectForKey:@"ItemTitle"]];
		[titleBoxMini setStringValue:[myPlayingItem objectForKey:@"ItemTitle"]];
	}
	else {
		[titleBox setStringValue:[[myPlayingItem objectForKey:@"MovieFile"]
				lastPathComponent]];
		[titleBoxMini setStringValue:[[myPlayingItem objectForKey:@"MovieFile"]
				lastPathComponent]];
	}
}
/************************************************************************************/
- (BOOL) changesRequireRestart
{
	if ([myPlayer isRunning])
		return [myPlayer changesNeedsRestart];
	return NO;
}
/************************************************************************************/
- (void) applyChangesWithRestart:(BOOL)restart
{
	[myPlayer applySettingsWithRestart:restart];	
}

/************************************************************************************
 MISC
 ************************************************************************************/
- (void) setMovieSize
{
	NSUserDefaults *preferences = [appController preferences];

	if ([preferences objectForKey:@"VideoFrameSize"]) {
		switch ([[preferences objectForKey:@"VideoFrameSize"] intValue]) {
		case 0 :		// normal
			[myPlayer setMovieSize:kDefaultMovieSize];
			break;
		case 1 :		// half
			[myPlayer setMovieSize:NSMakeSize(0.5, 0)];
			break;
		case 2 :		// double
			[myPlayer setMovieSize:NSMakeSize(2, 0)];
			break;
		case 3 :		// fit screen it (it is set before actual playback)
			if ([myPlayingItem objectForKey:@"ID_VIDEO_WIDTH"] &&
				[myPlayingItem objectForKey:@"ID_VIDEO_HEIGHT"]) {
				NSSize screenSize = [[NSScreen mainScreen] visibleFrame].size;
				double theWidth = ((screenSize.height - 28) /	// 28 pixels for window caption
						[[myPlayingItem objectForKey:@"ID_VIDEO_HEIGHT"] intValue] *
						[[myPlayingItem objectForKey:@"ID_VIDEO_WIDTH"] intValue]);
				if (theWidth < screenSize.width)
					[myPlayer setMovieSize:NSMakeSize(theWidth, 0)];
				else
					[myPlayer setMovieSize:NSMakeSize(screenSize.width, 0)];
			}
			break;
		case 4 :		// fit width
			if ([preferences objectForKey:@"VideoFrameWidth"])
				[myPlayer setMovieSize:NSMakeSize([[preferences
						objectForKey:@"VideoFrameWidth"] unsignedIntValue], 0)];
			else
				[myPlayer setMovieSize:kDefaultMovieSize];
			break;
		default :
			[myPlayer setMovieSize:kDefaultMovieSize];
			break;
		}
	}
	else
		[myPlayer setMovieSize:kDefaultMovieSize];
}
/************************************************************************************/
- (void) setSubtitlesEncoding
{
	NSUserDefaults *preferences = [appController preferences];
	if ([preferences objectForKey:@"SubtitlesFontPath"]) {
		if ([[[preferences objectForKey:@"SubtitlesFontPath"] lastPathComponent]
				caseInsensitiveCompare:@"font.desc"] != NSOrderedSame) {
		// if font is not a font.desc font then set subtitles encoding
			if (myPlayingItem) {
				if ([myPlayingItem objectForKey:@"SubtitlesEncoding"])
					[myPlayer setSubtitlesEncoding:[myPlayingItem objectForKey:@"SubtitlesEncoding"]];
				else
					[myPlayer setSubtitlesEncoding:
							[preferences objectForKey:@"SubtitlesEncoding"]];
			}
			else
				[myPlayer setSubtitlesEncoding:
						[preferences objectForKey:@"SubtitlesEncoding"]];
		}
		else
			[myPlayer setSubtitlesEncoding:nil];
	}
}

/************************************************************************************
 ACTIONS
 ************************************************************************************/
- (IBAction)changeVolume:(id)sender
{
	[[appController preferences]
			setObject:[NSNumber numberWithDouble:[sender doubleValue]]
			forKey:@"LastAudioVolume"];
	
	if (sender == volumeSlider)
		[volumeSliderMini setDoubleValue:[sender doubleValue]];
	else
		[volumeSlider setDoubleValue:[sender doubleValue]];
	
	[myPlayer setVolume:[sender intValue]];
	[myPlayer applySettingsWithRestart:NO];
}

/************************************************************************************/
- (IBAction)playPause:(id)sender
{
	if ([myPlayer status] > 0) {
		[myPlayer pause];				// if playing pause/unpause
		
	}
	else {
		
		// set the item to play
		if ([playListController indexOfSelectedItem] < 0)
			[playListController selectItemAtIndex:0];
		
		// if it is not set in the prefs by default play in window
		if ([[appController preferences] objectForKey:@"FullscreenByDefault"]) {
			if (![[[appController preferences] objectForKey:@"FullscreenByDefault"]
					isEqualToString:@"YES"])
				[myPlayer setFullscreen:NO];
		}
		
		// play the item
		[self playItem:[playListController selectedItem]];
	}
	[playListController updateView];
}

/************************************************************************************/
- (IBAction)seekBack:(id)sender
{
	if ([myPlayer isRunning])
		[myPlayer seek:-10 mode:MIRelativeSeekingMode];
	else {
		if ([playListController indexOfSelectedItem] < 1)
			[playListController selectItemAtIndex:0];
		else
			[playListController selectItemAtIndex:
					([playListController indexOfSelectedItem]-1)];
	}
	[playListController updateView];
}

/************************************************************************************/
- (IBAction)seekFwd:(id)sender
{
	if ([myPlayer isRunning])
		[myPlayer seek:10 mode:MIRelativeSeekingMode];
	else {
		if ([playListController indexOfSelectedItem] < ([playListController itemCount]-1))
			[playListController selectItemAtIndex:
					([playListController indexOfSelectedItem]+1)];
		else
			[playListController selectItemAtIndex:([playListController itemCount]-1)];
	}
	[playListController updateView];
}

/************************************************************************************/
- (IBAction)stop:(id)sender
{
	saveTime = NO;		// if user stops player, don't save time
	[myPlayer stop];
	[playListController updateView];
}

/************************************************************************************/
- (IBAction)switchFullscreen:(id)sender
{
    if ([myPlayer status] > 0) {
		// if mplayer is playing
		if ([myPlayer fullscreen])
			[myPlayer setFullscreen:NO];
		else
			[myPlayer setFullscreen:YES];
		[myPlayer applySettingsWithRestart:NO];
	}
	else {
		// if it is not playing
		// set the item to play
		if ([playListController indexOfSelectedItem] < 0)
			[playListController selectItemAtIndex:0];
		// set it to play in fullecreen
		[myPlayer setFullscreen:YES];	
		// play the item
		[self playItem:[playListController selectedItem]];
	}
}
/************************************************************************************/
- (IBAction)displayStats:(id)sender
{
	[myPlayer setUpdateStatistics:YES];
	[statsPanel makeKeyAndOrderFront:self];
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(statsClosed)
			name: NSWindowWillCloseNotification
			object:statsPanel];
}
/************************************************************************************/
- (IBAction)switchWindow:(id)sender
{
	if ([miniWindow isVisible]) {
		NSRect wframe = [miniWindow frame];
		NSPoint pos = wframe.origin;
		[mainWindow setFrameOrigin: pos];

		[mainWindow makeKeyAndOrderFront:self];
		[miniWindow orderOut:self];
	} else {
		NSRect wframe = [mainWindow frame];
		NSPoint pos = wframe.origin;
		[miniWindow setFrameOrigin: pos];

		/* show! */
		[miniWindow makeKeyAndOrderFront:self];
		[mainWindow orderOut:self];
	}
}
/************************************************************************************
 NOTIFICATION OBSERVERS
 ************************************************************************************/
- (void) appFinishedLaunching
{
	NSUserDefaults *prefs = [appController preferences];

	// play the last played movie if it is set to do so
	if ([prefs objectForKey:@"RememberPosition"] && [prefs objectForKey:@"LastTrack"]
			&& ![myPlayer isRunning]) {
		if ([[prefs objectForKey:@"RememberPosition"] isEqualToString:@"YES"] && 
				[prefs objectForKey:@"LastTrack"]) {
			[self playItem:[playListController
					itemAtIndex:[[prefs objectForKey:@"LastTrack"] intValue]]];
			[playListController
					selectItemAtIndex:[[prefs objectForKey:@"LastTrack"] intValue]];
		}
	}
	[prefs removeObjectForKey:@"LastTrack"];	
	
}
/************************************************************************************/
- (void) appShouldTerminate
{
	// save values before all is saved to disk and released
	if ([myPlayer status] > 0 &&
			[[appController preferences] objectForKey:@"RememberPosition"]) {
		if ([[[appController preferences] objectForKey:@"RememberPosition"]
				isEqualToString:@"YES"]) {
			[[appController preferences] setObject:[NSNumber
					numberWithInt:[playListController indexOfItem:myPlayingItem]]
					forKey:@"LastTrack"];
			if (myPlayingItem)
				[myPlayingItem setObject:[NSNumber
						numberWithFloat:[myPlayer seconds]] forKey:@"LastSeconds"];			
		}
	}
	
	// stop mplayer
	[myPlayer stop];	
}
/************************************************************************************/
// when application is terminating
- (void)appTerminating
{
	// remove observers
	[[NSNotificationCenter defaultCenter] removeObserver:self
			name: @"PlaybackStartNotification" object:myPlayer];
	[[NSNotificationCenter defaultCenter] removeObserver:self
			name: @"MIStateUpdatedNotification" object:myPlayer];
	
	[playImage release];
	[pauseImage release];
	[playImageMini release];
	[pauseImageMini release];
	
	[myPlayer release];
}
/************************************************************************************/
- (void) playbackStarted
{
	// the info dictionary should now be ready to be imported
	if ([myPlayer info] && myPlayingItem) {
		[myPlayingItem addEntriesFromDictionary:[myPlayer info]];
	}

	[playListController updateView];
}
/************************************************************************************/
- (void) statsClosed
{
	[myPlayer setUpdateStatistics:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self
			name: @"NSWindowWillCloseNotification" object:statsPanel];
}
/************************************************************************************/
- (void) statusUpdate:(NSNotification *)notification;
{
	int seconds;
	NSMutableDictionary *playingItem = myPlayingItem;
	
	// reset Idle time - Carbon PowerManager calls
	if ([playingItem objectForKey:@"ID_VIDEO_FORMAT"])	// if there is a video
#ifdef __COCOA__
		UpdateSystemActivity (UsrActivity);		// do not dim the display
#endif
/*	else									// if there's only audio
		UpdateSystemActivity (OverallAct);		// avoid sleeping only
*/
	// status did change
	if ([notification userInfo] && [[notification userInfo] objectForKey:@"PlayerStatus"]) {
		NSString *status;
		// status is changing
		// switch Play menu item title and playbutton image
		switch ([[[notification userInfo] objectForKey:@"PlayerStatus"] unsignedIntValue]) {
		case kOpening :
		case kBuffering :
		case kIndexing :
		case kPlaying :
			[playButton setImage:pauseImage];
			[playButtonMini setImage:pauseImageMini];
			[playMenuItem setTitle:NSLocalizedString(@"Pause",nil)];
			[playDockMenuItem setTitle:NSLocalizedString(@"Pause",nil)];
			break;
		case kPaused :
		case kStopped :
		case kFinished :
			[playButton setImage:playImage];
			[playButtonMini setImage:playImageMini];
			[playMenuItem setTitle:NSLocalizedString(@"Play",nil)];
			[playDockMenuItem setTitle:NSLocalizedString(@"Play",nil)];
			break;
		}
		switch ([[[notification userInfo] objectForKey:@"PlayerStatus"] unsignedIntValue]) {
		case kOpening :
			status = NSLocalizedString(@"Opening",nil);
			if ([playingItem objectForKey:@"ItemTitle"]) {
				[titleBox setStringValue:[playingItem objectForKey:@"ItemTitle"]];
				[titleBoxMini setStringValue:[playingItem objectForKey:@"ItemTitle"]];
			}
			else {
				[titleBox setStringValue:[[playingItem
						objectForKey:@"MovieFile"] lastPathComponent]];
				[titleBoxMini setStringValue:[[playingItem
						objectForKey:@"MovieFile"] lastPathComponent]];
			}
			// progress bars
#ifdef __COCOA__
			[progressBar setStyle:NSScrubbingBarProgressStyle];
#endif
			[progressBar setIndeterminate:YES];
			break;
		case kBuffering :
			status = NSLocalizedString(@"Buffering",nil);
			// progress bars
#ifdef __COCOA__
			[progressBar setStyle:NSScrubbingBarProgressStyle];
#endif
			[progressBar setIndeterminate:YES];
			break;
		case kIndexing :
			status = NSLocalizedString(@"Indexing",nil);
			// progress bars
#ifdef __COCOA__
			[progressBar setStyle:NSScrubbingBarProgressStyle];
#endif
			[progressBar setMaxValue:100];
			[progressBar setIndeterminate:NO];
			break;
		case kPlaying :
			status = NSLocalizedString(@"Playing",nil);
			// set default state of scrubbing bar
#ifdef __COCOA__
			[progressBar setStyle:NSScrubbingBarEmptyStyle];
#endif
			[progressBar setIndeterminate:NO];
			[progressBar setMaxValue:100];
			if ([playingItem objectForKey:@"ID_LENGTH"]) {
				if ([[playingItem objectForKey:@"ID_LENGTH"] intValue] > 0) {
					[progressBar setMaxValue:
							[[playingItem objectForKey:@"ID_LENGTH"] intValue]];
#ifdef __COCOA__
					[progressBar setStyle:NSScrubbingBarPositionStyle];
#endif
				}
			}
			break;
		case kPaused :
			status = NSLocalizedString(@"Paused",nil);
			// stop progress bars
			break;
		case kStopped :
		case kFinished :
			// reset status panel
			status = NSLocalizedString(@"N/A",nil);
			[statsCPUUsageBox setStringValue:status];
			[statsCacheUsageBox setStringValue:status];
			[statsAVsyncBox setStringValue:status];
			[statsDroppedBox setStringValue:status];
			[statsPostProcBox setStringValue:status];
			// reset status box
			status = @"";
			[titleBox setStringValue:@""];
			[titleBoxMini setStringValue:@""];
			[timeBox setStringValue:@"0:00:00"];
			[timeBoxMini setStringValue:@"0:00:00"];
			// hide progress bars
#ifdef __COCOA__
			[progressBar setStyle:NSScrubbingBarEmptyStyle];
#endif
			[progressBar setDoubleValue:0];
			[progressBar setIndeterminate:NO];
			// release the retained playing item
			[playingItem autorelease];
			myPlayingItem = nil;
			// update state of playlist
			[playListController updateView];
			// if playback finished itself (not by user) let playListController know
			if ([[[notification userInfo]
					objectForKey:@"PlayerStatus"] unsignedIntValue] == kFinished)
				[playListController finishedPlayingItem:playingItem];
			break;
		}
		[statsStatusBox setStringValue:status];
		[statusBox setStringValue:status];
		[statusBoxMini setStringValue:status];
	}
	
	seconds = (int)[myPlayer seconds];
	
	// update values
	switch ([myPlayer status]) {
	case kOpening :
		break;
	case kBuffering :
		if ([statsPanel isVisible])
			[statsCacheUsageBox setStringValue:[NSString localizedStringWithFormat:@"%3.1f %%",
				[myPlayer cacheUsage]]];
		break;
	case kIndexing :
		[progressBar setDoubleValue:[myPlayer cacheUsage]];
		break;
	case kPlaying :
		if ([[progressBar window] isVisible]) {
			if ([playingItem objectForKey:@"ID_LENGTH"])
				if ([[playingItem objectForKey:@"ID_LENGTH"] intValue] > 0)
					[progressBar setDoubleValue:[myPlayer seconds]];
				else
					[progressBar setDoubleValue:0];
			else
				[progressBar setDoubleValue:0];
		}
		if ([[timeBox window] isVisible])
				[timeBox setStringValue:[NSString stringWithFormat:@"%01d:%02d:%02d",
						seconds/3600,(seconds%3600)/60,seconds%60]];
		if ([[timeBoxMini window] isVisible])
				[timeBoxMini setStringValue:[NSString stringWithFormat:@"%01d:%02d:%02d",
						seconds/3600,(seconds%3600)/60,seconds%60]];
		// stats window
		if ([statsPanel isVisible]) {
			[statsCPUUsageBox setStringValue:[NSString localizedStringWithFormat:@"%d %%",
					[myPlayer cpuUsage]]];
			[statsCacheUsageBox setStringValue:[NSString localizedStringWithFormat:@"%d %%",
					[myPlayer cacheUsage]]];
			[statsAVsyncBox setStringValue:[NSString localizedStringWithFormat:@"%3.1f",
					[myPlayer syncDifference]]];
			[statsDroppedBox setStringValue:[NSString localizedStringWithFormat:@"%d",
					[myPlayer droppedFrames]]];
			[statsPostProcBox setStringValue:[NSString localizedStringWithFormat:@"%d",
					[myPlayer postProcLevel]]];
		}
		break;
	case kPaused :
		break;
	}
}
/************************************************************************************/
- (BOOL) validateMenuItem:(NSMenuItem *)aMenuItem
{
	if ((aMenuItem == stopMenuItem || aMenuItem == stopDockMenuItem) &&
			([myPlayer status] == kStopped || [myPlayer status] == kFinished)) {
		return NO;
	}
	return YES;
}
/************************************************************************************/
- (void) progresBarClicked:(NSNotification *)notification
{
	if ([myPlayer status] == kPlaying || [myPlayer status] == kPaused) {
		int theMode = MIPercentSeekingMode;
		if ([myPlayingItem objectForKey:@"ID_LENGTH"])
			if ([[myPlayingItem objectForKey:@"ID_LENGTH"] floatValue] != 0)
				theMode = MIAbsoluteSeekingMode;

		[myPlayer seek:[[[notification userInfo] 
				objectForKey:@"SBClickedValue"] floatValue] mode:theMode];
	}
}

/************************************************************************************
 DELEGATE METHODS
 ************************************************************************************/
// main window delegates
// exekutes when window zoom box is clicked
- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame
{
	if (sender == mainWindow) {
		[mainWindow orderOut:nil];
		[miniWindow makeKeyAndOrderFront:nil];
		[[appController preferences] setObject:@"YES" forKey:@"MinimizedWindow"];
		return NO;
	}
	if (sender == miniWindow) {
		[miniWindow orderOut:nil];
		[mainWindow makeKeyAndOrderFront:nil];
		[[appController preferences] setObject:@"NO" forKey:@"MinimizedWindow"];
		return NO;
	}
		
	return YES;
}
/************************************************************************************/
// executes when window is closed
- (void)windowWillClose:(NSNotification *)aNotification
{
	[appController quitApp];
}
@end
