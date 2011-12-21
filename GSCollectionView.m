//
//  GSCollectionView.m
//  Glyphs Mini
//
//  Created by Georg Seifert on 17.12.11.
//  Copyright 2011 schriftgestaltung.de. All rights reserved.
//

#import "GSCollectionView.h"
#import "GSFontViewController.h"
#import <GlyphsCore/GSGlyph.h>
#import "BCCollectionViewGroup.h"
#import "BCCollectionViewLayoutItem.h"
#import "BCCollectionViewLayoutManager.h"
#import "BCGeometryExtensions.h"

static void *ContentArrayBindingContext = (void *)@"contentArray";
static void *SelectionIndexesBindingContext = (void *)@"selectionIndexes";
static void *ItemSizeBindingContext = (void *)@"itemSize";

@implementation GSCollectionView

- (id) initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	_border = 18;
	numberOfPreRenderedRows = 5;
	return self;
}

- (void)bind:(NSString *)binding
	toObject:(id)observableObject
 withKeyPath:(NSString *)keyPath
	 options:(NSDictionary *)options
{
	// Observe the observableObject for changes -- note, pass binding identifier
	// as the context, so you get that back in observeValueForKeyPath:...
	// This way you can easily determine what needs to be updated.
	//UKLog(@"%@ %@, %@, %@",binding, observableObject, [observableObject class], keyPath);
	
	if ([binding isEqualToString:@"contentArray"])
	{
		[observableObject addObserver:self
						   forKeyPath:keyPath
							  options:0
							  context:ContentArrayBindingContext];
		
		// Register what object and what keypath are
		// associated with this binding
		if (_observedObjectForContentArray) {
			[_observedObjectForContentArray release];
		}
		_observedObjectForContentArray = [observableObject retain];
		if (_observedKeyPathForContentArray) {
			[_observedKeyPathForContentArray release];
		}
		_observedKeyPathForContentArray = [keyPath retain];
		//UKLog(@"observableObject: %@ observedKeyPathForContentArray: %@ array: %@", observableObject, observedKeyPathForContentArray, [observableObject valueForKeyPath:observedKeyPathForContentArray]);
		
		//[self setValue:[_observedObjectForContentArray valueForKeyPath:_observedKeyPathForContentArray] forKey:@"contentArray"];
		[self reloadDataWithItems:[_observedObjectForContentArray valueForKeyPath:_observedKeyPathForContentArray] emptyCaches:NO];
	}
	if ([binding isEqualToString:@"selectionIndexes"])
	{
		[observableObject addObserver:self
						   forKeyPath:keyPath
							  options:0
							  context:SelectionIndexesBindingContext];
		
		// Register what object and what keypath are
		// associated with this binding
		if (_observedObjectForSelectionIndexes) {
			[_observedObjectForSelectionIndexes release];
		}
		_observedObjectForSelectionIndexes = [observableObject retain];
		if (_observedKeyPathForSelectionIndexes) {
			[_observedKeyPathForSelectionIndexes release];
		}
		_observedKeyPathForSelectionIndexes = [keyPath retain];
		//UKLog(@"observedObjectForSelectionIndex: %@ observedKeyPathForSelectionIndex: %@ intValue: %d", observedObjectForSelectionIndex,observedKeyPathForSelectionIndex, [[observedObjectForSelectionIndex valueForKeyPath:observedKeyPathForSelectionIndex] intValue]);
		
		//[self setValue:[_observedObjectForSelectionIndexes valueForKeyPath:_observedKeyPathForSelectionIndexes]];
		[selectionIndexes release];
		selectionIndexes = [[_observedObjectForSelectionIndexes valueForKeyPath:_observedKeyPathForSelectionIndexes] mutableCopy];
		//[self setValue:[observedObjectForSelectionIndex valueForKeyPath:observedKeyPathForSelectionIndex] forKey:@"selectionIndex"];
	}	
}
- (void) unbind:bindingName {
	//UKLog(@"GSSegmentedControl:unbind" );
	if ([bindingName isEqualToString:@"contentArray"])
	{
		[_observedObjectForContentArray removeObserver:self forKeyPath:_observedKeyPathForContentArray];
		[_observedObjectForContentArray release], _observedObjectForContentArray = nil;
		[_observedKeyPathForContentArray release], _observedKeyPathForContentArray = nil;
	}
	if ([bindingName isEqualToString:@"selectionIndexes"])
	{
		[_observedObjectForSelectionIndexes removeObserver:self forKeyPath:_observedKeyPathForSelectionIndexes];
		[_observedObjectForSelectionIndexes release], _observedObjectForSelectionIndexes = nil;
		[_observedKeyPathForSelectionIndexes release], _observedKeyPathForSelectionIndexes = nil;
	}
	[super unbind:bindingName];
}
- (void) observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	// You passed the binding identifier as the context when registering
	// as an observer--use that to decide what to update...
	UKLog(@"keyPath: %@", keyPath );
	if (context == ContentArrayBindingContext)
	{
		id newContentArray = [_observedObjectForContentArray valueForKeyPath:_observedKeyPathForContentArray];
		//NSLog(@"GSSegmentedControl:observeValueForKeyPath:Masters %@", newMasters );
		if ((newContentArray == NSNoSelectionMarker) ||
			(newContentArray == NSNotApplicableMarker) ||
			(newContentArray == NSMultipleValuesMarker))
		{
			//NSLog(@"GSSegmentedControl:observeValueForKeyPath:badSelectionForMasters" );
			_badSelectionForContentArray = YES;
		}
		else {
			_badSelectionForContentArray = NO;
			//UKLog(@"newContentArray: %@", newContentArray);
			//[self setContentArray:newContentArray];
			[self reloadDataWithItems:newContentArray emptyCaches:NO];
			//[self softReloadVisibleViewControllers];
			lastSelectionIndex = NSNotFound;
		} 
	}
	else if (context == SelectionIndexesBindingContext) {
		id newSelectionIndex = [_observedObjectForSelectionIndexes valueForKeyPath:_observedKeyPathForSelectionIndexes];
		
		//UKLog(@"observedObjectForSelectionIndex %@", _observedObjectForSelectionIndexes );
		if ((newSelectionIndex == NSNoSelectionMarker) ||
			(newSelectionIndex == NSNotApplicableMarker) ||
			(newSelectionIndex == NSMultipleValuesMarker))
		{
			//NSLog(@"GSSegmentedControl:observeValueForKeyPath:badSelectionForMasters" );
			_badSelectionForSelectionIndexes = YES;
		}
		else {
			_badSelectionForSelectionIndexes = NO;
			//[self setValue:newSelectionIndex forKey:@"selectionIndex"];
			UKLog(@"= %d newSelectionIndex: %@", _updateing, newSelectionIndex);
			//if (!_updateing) {
				NSIndexSet *OldSelectionIndexes = selectionIndexes;

				selectionIndexes = [newSelectionIndex mutableCopy];
				//[[self window] makeFirstResponder:self];
				//[self softReloadVisibleViewControllers];
				for (NSString *number in visibleViewControllers) {
					NSUInteger index = [number integerValue];
					//NSViewController *controller = [visibleViewControllers objectForKey:number];
					if (index < [contentArray count] && [selectionIndexes containsIndex:index]) {
						[self delegateUpdateSelectionForItemAtIndex:index];
					}
					else {
						[self delegateUpdateDeselectionForItemAtIndex:index];
					}
				}
				NSMutableIndexSet *newIndexes = [newSelectionIndex mutableCopy];
				[newIndexes removeIndexes:OldSelectionIndexes];
				//UKLog(@"setSelectionIndexes: %@", indexes);
				NSInteger Count = [contentArray count];
				if (Count > [newIndexes firstIndex]) {
					NSInteger ItemIndex;
					if (lastSelectionIndex < Count && lastSelectionIndex >= 0) {
						ItemIndex = lastSelectionIndex;
					}
					else {
						ItemIndex = [newIndexes firstIndex];
					}
					NSRect ItemRect = [layoutManager rectOfItemAtIndex:ItemIndex];
					if (ItemRect.size.width > 0)
						[self scrollRectToVisible:NSInsetRect(ItemRect, -10, -10) ];
				}
				[newIndexes release];
				[OldSelectionIndexes release];
				
			//}
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}

	//NSLog(@"GSSegmentedControl:observeValueForKeyPath:ende" );
	[self setNeedsDisplay:YES];
}

- (void) delegateCollectionViewSelectionDidChange {
	UKLog(@"__selectionIndexes: %@", selectionIndexes);
	if (!selectionChangedDisabled) {
		//[[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(collectionViewSelectionDidChange:) target:delegate argument:self];
		//[_observedObjectForSelectionIndexes performSelector:@selector(setSelectionIndexes:) withObject:selectionIndexes afterDelay:0.0];
		_updateing = YES;
		[(NSArrayController*)_observedObjectForSelectionIndexes setSelectionIndexes:selectionIndexes];
		_updateing = NO;
	}
}

- (void) reloadDataWithItems:(NSArray *)newContent emptyCaches:(BOOL)shouldEmptyCaches {
	
	NSMutableArray * Groups = [[NSMutableArray alloc] init];
	NSString * GroupTitle = nil;
	BCCollectionViewGroup * group = nil;
	int i = 0;
	for (GSGlyph* currGlyph in newContent) {
		NSString * currGroupTitle = [currGlyph category];
		if ([currGroupTitle isEqualToString:@"Letter"]) {
			currGroupTitle = [currGroupTitle stringByAppendingFormat:@", %@", currGlyph.script];
		}
		if ([currGroupTitle length] == 0) {
			currGroupTitle = @"Other";
		}
		if (/*currGroupTitle &&*/ ![currGroupTitle isEqualToString:GroupTitle]) {
			if (group) {
				NSRange ItemRange = [group itemRange];
				ItemRange.length = i - ItemRange.location;
				[group setItemRange:ItemRange];
			}
			group = [[BCCollectionViewGroup alloc] init];
			[group setTitle:currGroupTitle];
			[group setItemRange:NSMakeRange(i, 0)];
			[Groups addObject:group];
			[group release];
			GroupTitle = currGroupTitle;
		}
		i++;
	}
	if ([Groups count] > 0) {
		[self reloadDataWithItems:newContent groups:Groups emptyCaches:shouldEmptyCaches];
	}
	else {
		[self reloadDataWithItems:newContent groups:nil emptyCaches:shouldEmptyCaches];
	}
	[Groups release];
}
- (void)setNeedsDisplayInRect:(NSRect)invalidRect {
	if ([self visibleRect].size.height > invalidRect.size.height + 10) {
		UKLog(@"%@", NSStringFromRect(invalidRect));
	}
	
	[super setNeedsDisplayInRect:invalidRect];
}
- (void)drawRect:(NSRect)dirtyRect
{
	//UKLog(@"dirtyRect: %@", NSStringFromRect(dirtyRect));
	
	NSRect VisibleRect = [self visibleRect];
	//UKLog(@"VisibleRect: %@", NSStringFromRect(VisibleRect));
	if ([[self window] isKeyWindow]) {
		[[NSColor grayColor] set];
	}
	else {
		[[NSColor lightGrayColor] set];
	}

	
	//[backgroundColor ? backgroundColor : [NSColor whiteColor] set];
	NSRectFill(VisibleRect);
	if ([contentArray count] == 0) return;
	[[NSColor whiteColor] set];
	NSArray * VisibleIndexes = [[visibleGroupViewControllers allKeys] sortedArrayUsingSelector:@selector(compare:)];
	[[NSGraphicsContext currentContext] saveGraphicsState];
	NSShadow* Shadow = [[NSShadow alloc] init];
	[Shadow setShadowBlurRadius:5];
	[Shadow setShadowOffset:NSMakeSize(1,-1)];
	[Shadow setShadowColor:[NSColor blackColor]];
	[Shadow set];
	
	//NSRectFill( NSInsetRect(VisibleRect, _border * 0.5f, 0));
	NSBezierPath * BezierPath = [[NSBezierPath alloc] init];
	//	}
	NSUInteger LastVerticalOffset = NSNotFound;
	NSInteger VerticalOffset;
	for (NSNumber* GoupeIndex in VisibleIndexes) {
		
		NSUInteger Index = [GoupeIndex integerValue];
		NSViewController * Group = [visibleGroupViewControllers objectForKey:GoupeIndex];
		if (Index > 0 && LastVerticalOffset == NSNotFound ) {
			LastVerticalOffset = NSMinY(VisibleRect) - 8;
		}
		VerticalOffset = NSMinY([[Group view] frame]) +8;
		if (VerticalOffset - 4 > LastVerticalOffset && LastVerticalOffset < NSNotFound) {
			NSRect GroupFrame = NSMakeRect(_border * 0.5f , LastVerticalOffset, VisibleRect.size.width - _border, VerticalOffset - LastVerticalOffset - 4);
			//[BezierPath appendBezierPathWithRoundedRect:GroupFrame xRadius:3 yRadius:3];
			//[BezierPath appendBezierPathWithRect:GroupFrame];
			NSRectFill(GroupFrame);
		}
		LastVerticalOffset = VerticalOffset;
	}
	if (LastVerticalOffset == NSNotFound) {
		LastVerticalOffset = NSMinY(VisibleRect) - 7;
	}
	BCCollectionViewLayoutItem *layoutItem = [[layoutManager itemLayouts] lastObject];
	VerticalOffset = NSMaxY([layoutItem itemRect]) + 4;
	//UKLog(@"__Last VerticalOffset : %d", VerticalOffset);
	if (VerticalOffset > 10) {
		NSRect GroupFrame = NSMakeRect(_border * 0.5f , LastVerticalOffset, VisibleRect.size.width - _border, VerticalOffset - LastVerticalOffset);
		//[BezierPath appendBezierPathWithRoundedRect:GroupFrame xRadius:3 yRadius:3];
		//[BezierPath appendBezierPathWithRect:GroupFrame];
		NSRectFill(GroupFrame);
		
		//UKLog(@"__BezierPath: %@", BezierPath);
		//[BezierPath fill];
	}
	[BezierPath release];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	[[NSColor grayColor] set];
	NSFrameRect(BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation));
	
//	if ([selectionIndexes count] > 0 && [self shoulDrawSelections]) {
//		for (NSNumber *number in visibleViewControllers)
//			if ([selectionIndexes containsIndex:[number integerValue]])
//				[self drawItemSelectionForInRect:[[[visibleViewControllers objectForKey:number] view] frame]];
//	}
	
//	if (dragHoverIndex != NSNotFound && [self shoulDrawHover])
//		[self drawItemSelectionForInRect:[[[visibleViewControllers objectForKey:[NSNumber numberWithInteger:dragHoverIndex]] view] frame]];
}

- (void)drawItemSelectionForInRect:(NSRect)aRect
{
	return;
/*	NSRect insetRect = NSInsetRect(aRect, 10, 10);
	if ([self needsToDrawRect:insetRect]) {
		[[NSColor lightGrayColor] set];
		[[NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:10 yRadius:10] fill];
	}
 */
}
- (void) resizeFrameToFitContents {
	NSRect frame = [self frame];
	frame.size.height = [self visibleRect].size.height;
	if ([contentArray count] > 0) {
		BCCollectionViewLayoutItem *layoutItem = [[layoutManager itemLayouts] lastObject];
		frame.size.height = MAX(frame.size.height, NSMaxY([layoutItem itemRect]) + 8);
	}
	[self setFrame:frame];
}
#pragma mark Responder
- (void) keyDown:(NSEvent *) theEvent {
	unichar Keystroke = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	//UKLog(@"Keystroke: %d NSDownArrowFunctionKey: %d Mask: %d NSCommandKeyMask: %d = %d", Keystroke, NSDownArrowFunctionKey, [theEvent modifierFlags] & NSCommandKeyMask, NSCommandKeyMask, ([theEvent modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask); 
	if (Keystroke == NSDownArrowFunctionKey && ([theEvent modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask ) {
		[(GSFontViewController*)delegate openSelectedGlyphsInNewTab];
	}
	didProcessEvent = NO;
	[self interpretKeyEvents: [NSArray arrayWithObject: theEvent]];
	if (!didProcessEvent) {
		if ([theEvent keyCode] == 36 || (Keystroke != NSLeftArrowFunctionKey && Keystroke != NSRightArrowFunctionKey && Keystroke != NSUpArrowFunctionKey && Keystroke != NSDownArrowFunctionKey) ) {
			[(GSFontViewController*)delegate keyDown:theEvent];
		}
		else {
			[super keyDown:theEvent];
		}
	}
}
- (void) doCommandBySelector: (SEL)aSelector {
	//UKLog(@"%s", aSelector);
	if ([self respondsToSelector:aSelector]) {
		didProcessEvent = YES;
		[self performSelector: aSelector];
	}
}
- (void) mouseDown:(NSEvent *)theEvent {
	if([theEvent clickCount] > 1) {
		//UKLog(@"doubleclick: %@", [self controller]);
		[(GSFontViewController*)delegate openSelectedGlyphsInNewTab];
		return;
	}
	else {
		[super mouseDown:theEvent];
	}
}
- (void) insertText: (id) aString {
	UKLog(@"aString: %@", aString);
}
- (void) scrollToBeginningOfDocument:(id) sender {
	[self scrollRectToVisible:[[[[self contentArray] objectAtIndex:0] view] frame]];
	
}
- (void) scrollToEndOfDocument:(id) sender {
	[self scrollRectToVisible:[[[[self contentArray] lastObject] view] frame]];
}

- (void) scrollPageUp:(id) sender {
	NSRect Frame = [self visibleRect];
	NSSize SubViewSize = [self cellSize];
	NSInteger itemsVisibel = (NSInteger)floor(Frame.size.height / SubViewSize.height);
	
	Frame.origin.y -= itemsVisibel * SubViewSize.height;// Frame.size.height;
	[self scrollRectToVisible:Frame];
}
- (void) scrollPageDown:(id) sender {
	NSRect Frame = [self visibleRect];
	NSSize SubViewSize = [self cellSize];
	NSInteger itemsVisibel = (NSInteger)floor(Frame.size.height / SubViewSize.height);
	
	Frame.origin.y += itemsVisibel * SubViewSize.height;// Frame.size.height;
	
	[self scrollRectToVisible:Frame];	
}
- (void) pageUpAndModifySelection:(id) sender {
	[self scrollPageUp:sender];
}
- (void) pageDownAndModifySelection:(id) sender {
	[self scrollPageDown:sender];
}
@end
