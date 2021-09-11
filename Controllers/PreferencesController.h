/*
 *  PreferencesController.h
 *  MPlayer OS X
 *
 *	Description:
 *		It's controller forPreferences dialog
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

@interface PreferencesController : NSObject
{
	// controller outlets
	IBOutlet id appController;
	IBOutlet id playListController;
	IBOutlet id playerController;
	// GUI outlets
	IBOutlet NSPanel *prefsPanel;
	IBOutlet id smallTextButton;
	IBOutlet id rememberButton;
	IBOutlet id videoSizeMenu;
	IBOutlet id videoWidthButton;
	IBOutlet id videoAspectMenu;
	IBOutlet id defaultFullscreenButton;

	//BETA
	IBOutlet id rootwinButton;
	IBOutlet id tileButton;
	IBOutlet id nosoundbutton;
	IBOutlet id secMonitorbutton;
	IBOutlet id Postprocesingbutton;


	
	IBOutlet id dropFramesButton;
	IBOutlet id subFontMenu;
	IBOutlet id subEncodingMenu;
	IBOutlet id subSizeMenu;
	IBOutlet id enableCacheButton;
	IBOutlet id cacheSizeSlider;
	IBOutlet id cacheSizeBox;
	IBOutlet id addParamsButton;
	IBOutlet id addParamsBox;
}
// misc
- (void) reloadValues;
- (void) initFontMenu;
// actions
- (IBAction)displayPreferences:(id)sender;
- (IBAction)applyPrefs:(id)sender;
- (IBAction)cancelPrefs:(id)sender;
- (IBAction)prefsChanged:(id)sender;
- (IBAction)enableControls:(id)sender;
- (IBAction)cacheSizeChanged:(id)sender;
// delegate methods
- (void) sheetDidEnd:(NSWindow *)sheet
		returnCode:(int)returnCode
		contextInfo:(void *)contextInfo;
@end
