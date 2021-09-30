/*
 *  PlayerCtrllr.h
 *  MPlayer OS X
 *
 *	Description:
 *		Controller for player controls, status box and statistics panel on side of UI
 *	and for MplayerInterface on side of data
 *
 *  Created by Jan Volf
 *	<javol@seznam.cz>
 *  Copyright (c) 2003 Jan Volf. All rights reserved.
 */

#ifdef __COCOA__
#import <Cocoa/Cocoa.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "MplayerInterface.h"

@interface PlayerCtrllr : NSObject
{
	// other controllers outlets
	IBOutlet id	playListController;
	IBOutlet id appController;
	IBOutlet id prefsController;
	IBOutlet id settingsController;
	
	// Control menu outlets
	IBOutlet id playMenuItem;
	IBOutlet id stopMenuItem;
	IBOutlet id seekBackMenuItem;
	IBOutlet id seekFwdMenuItem;
	// Dock menu outlets
	IBOutlet id playDockMenuItem;
	IBOutlet id stopDockMenuItem;
	
	// main window
	IBOutlet id mainWindow;
	IBOutlet NSButton *playButton;
	IBOutlet NSSlider *volumeSlider;
	// main player status box outlets
	IBOutlet id statusBox;
	IBOutlet id titleBox;
	IBOutlet id timeBox;
	IBOutlet id progressBar;
	
	// mini window
	IBOutlet id miniWindow;
	IBOutlet NSButton *playButtonMini;
	IBOutlet NSSlider *volumeSliderMini;
	// mini player status box outlets
	IBOutlet id statusBoxMini;
	IBOutlet id titleBoxMini;
	IBOutlet id timeBoxMini;

	// statistics panel outlets
	IBOutlet id statsPanel;
	IBOutlet id statsAVsyncBox;
	IBOutlet id statsCacheUsageBox;
	IBOutlet id statsCPUUsageBox;
	IBOutlet id statsPostProcBox;
	IBOutlet id statsDroppedBox;
	IBOutlet id statsStatusBox;
	
	// properties
	MplayerInterface *myPlayer;
	// actual movie parametters
	NSMutableDictionary *myPlayingItem;
	BOOL saveTime;
	int playerStatus;
	unsigned movieSeconds;		// stores actual movie seconds for further use
	BOOL  fullscreenStatus;
	// images
	NSImage	*playImage;
	NSImage *pauseImage;
	NSImage *playImageMini;
	NSImage *pauseImageMini;
}

// interface
- (void) displayWindow: (BOOL)minimized;
- (BOOL) preflightItem:(NSMutableDictionary *)anItem;
- (void) playItem:(NSMutableDictionary *)anItem;
- (NSMutableDictionary *) playingItem;
- (BOOL) isRunning;
- (BOOL) isPlaying;
- (void) applyPrefs;
- (void) applySettings;
- (BOOL) changesRequireRestart;
- (void) applyChangesWithRestart:(BOOL)restart;

// misc
- (void) setMovieSize;
- (void) setSubtitlesEncoding;

// player control actions
- (IBAction)changeVolume:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)seekBack:(id)sender;
- (IBAction)seekFwd:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)switchFullscreen:(id)sender;
- (IBAction)displayStats:(id)sender;
- (IBAction)switchWindow:(id)sender;

// notification observers
- (void) appFinishedLaunching;
- (void) appShouldTerminate;
- (void) appTerminating;
- (void) playbackStarted;
- (void) statsClosed;
- (void) statusUpdate:(NSNotification *)notification;
- (BOOL) validateMenuItem:(NSMenuItem *)aMenuItem;
- (void) progresBarClicked:(NSNotification *)notification;

// window delegate methods
- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame;
- (void)windowWillClose:(NSNotification *)aNotification;

@end
