/*
 *  ScrubbingBar.h
 *  MPlayer OS X
 *
 *  Created by Jan Volf on Mon Apr 14 2003.
 *	<javol@seznam.cz>
 *  Copyright (c) 2003 Jan Volf. All rights reserved.
 */

#import "ScrubbingBar.h"


@implementation ScrubbingBar:NSProgressIndicator
- (void)awakeFromNib
{
	myStyle = NSScrubbingBarEmptyStyle;
	// load images that forms th scrubbing bar
	scrubBarEnds = [[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"scrub_bar_ends" ofType:@"tif"]];
	scrubBarRun = [[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"scrub_bar_run" ofType:@"tif"]];
	scrubBarBadge = [[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource:@"scrub_bar_badge" ofType:@"tif"]];
}

- (void) dealloc
{
	if (scrubBarEnds) [scrubBarEnds release];
	if (scrubBarRun) [scrubBarRun release];
	if (scrubBarBadge) [scrubBarBadge release];
	
	[super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent
{
#ifdef __COCOA__
	if ([self style] == NSScrubbingBarPositionStyle)
		postNotification(self, theEvent);
#endif
}
- (void)mouseDragged:(NSEvent *)theEvent
{
#ifdef __COCOA__
	if ([self style] == NSScrubbingBarPositionStyle)
		postNotification(self, theEvent);
#endif
}
- (BOOL)mouseDownCanMoveWindow
{
#ifdef __COCOA__
	if ([self style] == NSScrubbingBarPositionStyle)
		return NO;
#endif
	return YES;
}
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
#ifdef __COCOA__
	if ([self style] == NSScrubbingBarPositionStyle)
		return YES;
#endif
	return NO;

}

- (BOOL)isFlipped
{	
	if (myStyle == NSScrubbingBarProgressStyle)
		return YES;
	return NO;
}

- (void)drawRect:(NSRect)aRect
{
	if (myStyle == NSScrubbingBarProgressStyle)
		[super drawRect:aRect];
	else {
		float runLength = [self bounds].size.width - [scrubBarEnds size].width;
		float endWidth = [scrubBarEnds size].width / 2;		// each half of the picture is one end
		float yOrigin = [self bounds].origin.y + 1;
		double theValue = [self doubleValue] / ([self maxValue] - [self minValue]);
		
		[scrubBarEnds compositeToPoint:NSMakePoint([self bounds].origin.x, yOrigin)
				fromRect:NSMakeRect(0,0,endWidth,[scrubBarEnds size].height)
				operation:NSCompositeSourceOver];
	
		[scrubBarEnds compositeToPoint:
				NSMakePoint(NSMaxX([self bounds]) - endWidth,yOrigin)
				fromRect:NSMakeRect(endWidth,0,endWidth,[scrubBarEnds size].height)
				operation:NSCompositeSourceOver];
		// resize the bar run frame if needed
		if ([scrubBarRun size].width != runLength) {
			[scrubBarRun setScalesWhenResized:YES];
			[scrubBarRun setSize:NSMakeSize(runLength, [scrubBarRun size].height)];
			[scrubBarRun recache];
		}
		[scrubBarRun compositeToPoint:NSMakePoint(endWidth,yOrigin)
				operation:NSCompositeSourceOver];

#ifdef __COCOA__		
		switch ([self style]) {
		case NSScrubbingBarPositionStyle :
			[scrubBarBadge compositeToPoint:
					NSMakePoint(endWidth + (runLength - [scrubBarBadge size].width) * theValue,
					yOrigin)
					operation:NSCompositeSourceOver];
			break;
		case NSScrubbingBarProgressStyle :
			
			break;
		default :
			break;
		}
#endif
	}
}

- (NSScrubbingBarStyle)style
{
	return myStyle;
}
- (void)setStyle:(NSScrubbingBarStyle)style
{
	myStyle = style;
	if (style == NSScrubbingBarProgressStyle)
		[self startAnimation:nil];
	else
		[self stopAnimation:nil];
	[self display];
}
- (void)incrementBy:(double)delta
{
	[super incrementBy:delta];
	[self display];
}
- (void)setDoubleValue:(double)doubleValue
{
	[super setDoubleValue:doubleValue];
	[self display];
}
- (void)setIndeterminate:(BOOL)flag
{
	[super setIndeterminate:flag];
	[self display];
}
- (void)setMaxValue:(double)newMaximum
{
	[super setMaxValue:newMaximum];
	[self display];
}
- (void)setMinValue:(double)newMinimum
{
	[super setMinValue:newMinimum];
	[self display];
}
@end

int postNotification (id self, NSEvent *theEvent)
{
	NSPoint thePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	double theValue;
	float minX = [self bounds].origin.x + 5,
		maxX = NSMaxX([self bounds]) - 7,
		minY = 2,
		maxY = 12;
	// set the value
	if (thePoint.y >= minY && thePoint.y < maxY) {
			if (thePoint.x < minX)
				theValue = [self minValue];
			else if (thePoint.x >= maxX)
				theValue = [self maxValue];
			else
				theValue = [self minValue] + (([self maxValue] - [self minValue]) *
						(thePoint.x - minX) / (maxX - minX));
		
		[[NSNotificationCenter defaultCenter]
				postNotificationName:@"SBBarClickedNotification"
				object:self
				userInfo:[NSDictionary 
						dictionaryWithObject:[NSNumber numberWithDouble:theValue]
						forKey:@"SBClickedValue"]];
		return 1;
	}
	
	return 0;
}
