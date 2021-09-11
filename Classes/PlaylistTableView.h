/*
 PlaylistTableView.h

 Author: MCF
 
 */

#ifdef __COCOA__
#import <Cocoa/Cocoa.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "PlayListCtrllr.h"
#import "PlayerCtrllr.h"

@interface PlaylistTableView : NSTableView
{
    IBOutlet PlayListCtrllr	*playListController;
	IBOutlet PlayerCtrllr	*playerController;
}
// 1st responderaction implementation
- (void)keyDown:(NSEvent *)theEvent;
- (void)clear:(id)sender;
// overriding methods
- (void) highlightSelectionInClipRect:(NSRect)rect;
// misc
- (void) drawStripesInRect:(NSRect)clipRect;
// delegate methods
- (BOOL)validateMenuItem:(id <NSMenuItem>)anItem;
@end
