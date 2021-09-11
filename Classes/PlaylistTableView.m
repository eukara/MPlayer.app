/*
 PlaylistTableView.m

 Author: MCF, with help from PW, augmented by JaVol
 
 */

#import "PlaylistTableView.h"

// RGB values for stripe color (light blue)
#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)
static NSColor *sStripeColor = nil;

@implementation PlaylistTableView

/************************************************************************************
 ACTION IMPLEMENTATION
 ************************************************************************************/
- (void)keyDown:(NSEvent *)theEvent
{
	unichar pressedKey;
	
	// check if the backspace is pressed
	pressedKey = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	if ((pressedKey == NSDeleteFunctionKey || pressedKey == 127) && [self selectedRow] >= 0)
		[playListController deleteSelection];
	else
		[super keyDown:theEvent];
}
/************************************************************************************/
-(void)clear:(id)sender
{
	[playListController deleteSelection];
}
/************************************************************************************
 OVERRIDING METHODS
 ************************************************************************************/
// This is called after the table background is filled in, but before the cell contents are drawn.
// We override it so we can do our own light-blue row stripes a la iTunes.
- (void) highlightSelectionInClipRect:(NSRect)rect {
	[self drawStripesInRect:rect];
    [super highlightSelectionInClipRect:rect];
}

/************************************************************************************/
// This routine does the actual blue stripe drawing, filling in every other row of the table
// with a blue background so you can follow the rows easier with your eyes.
- (void) drawStripesInRect:(NSRect)clipRect {
    NSRect stripeRect;
    float fullRowHeight = [self rowHeight] + [self intercellSpacing].height;
    float clipBottom = NSMaxY(clipRect);
    int firstStripe = clipRect.origin.y / fullRowHeight;
    if (firstStripe % 2 == 0)
        firstStripe++;			// we're only interested in drawing the stripes
                         // set up first rect
    stripeRect.origin.x = clipRect.origin.x;
    stripeRect.origin.y = firstStripe * fullRowHeight;
    stripeRect.size.width = clipRect.size.width;
    stripeRect.size.height = fullRowHeight;
    // set the color
    if (sStripeColor == nil)
        sStripeColor = [[NSColor colorWithCalibratedRed:STRIPE_RED green:STRIPE_GREEN blue:STRIPE_BLUE alpha:1.0] retain];
    [sStripeColor set];
    // and draw the stripes
    while (stripeRect.origin.y < clipBottom) {
        NSRectFill(stripeRect);
        stripeRect.origin.y += fullRowHeight * 2.0;
    }
}

/************************************************************************************
 DELEGATE METHODS
 ************************************************************************************/
- (BOOL)validateMenuItem:(id <NSMenuItem>)anItem
{
	BOOL	result = NO;
	// clear menu item
	if ([anItem action] == @selector(clear:)) {
		if ([self selectedRow] >= 0)
			result = YES;
		else
			result = NO;
	}
	
	// select all menu item
	if ([anItem action] == @selector(selectAll:)) {
		if ([self numberOfRows] > 0)
			result = YES;
		else
			result = NO;
	}
	
	return result;
}

@end
