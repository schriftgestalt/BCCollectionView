//	Created by Pieter Omvlee on 24/11/2010.
//	Copyright 2010 Bohemian Coding. All rights reserved.

#import "BCCollectionView.h"
#import "BCGeometryExtensions.h"
#import "BCCollectionViewLayoutManager.h"
#import "BCCollectionViewLayoutItem.h"
#import "BCCollectionViewGroup.h"

static void *ContentArrayBindingContext = (void *)@"contentArray";
static void *SelectionIndexesBindingContext = (void *)@"selectionIndexes";
static void *ItemSizeBindingContext = (void *)@"itemSize";

@implementation BCCollectionView
@synthesize delegate, contentArray, groups, backgroundColor, originalSelectionIndexes, zoomValueObserverKey, accumulatedKeyStrokes, numberOfPreRenderedRows, layoutManager;

@synthesize border = _border;

@dynamic visibleViewControllerArray;

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		animated = YES;
		reusableViewControllers		= [[NSMutableArray alloc] init];
		visibleViewControllers		= [[NSMutableDictionary alloc] init];
		contentArray				= [[NSArray alloc] init];
		selectionIndexes			= [[NSMutableIndexSet alloc] init];
		dragHoverIndex				= NSNotFound;
		accumulatedKeyStrokes		= [[NSString alloc] init];
		numberOfPreRenderedRows		= 3;
		layoutManager				= [[BCCollectionViewLayoutManager alloc] initWithCollectionView:self];
		visibleGroupViewControllers = [[NSMutableDictionary alloc] init];
		//[self addObserver:self forKeyPath:@"backgroundColor" options:0 context:NULL];
		_border = 10;
		NSClipView *enclosingClipView = [[self enclosingScrollView] contentView];
		[enclosingClipView setPostsBoundsChangedNotifications:YES];
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:enclosingClipView];
		[center addObserver:self selector:@selector(viewDidResize) name:NSViewFrameDidChangeNotification object:self];
	}
	return self;
}

- (id) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		animated = YES;
		reusableViewControllers		= [[NSMutableArray alloc] init];
		visibleViewControllers		= [[NSMutableDictionary alloc] init];
		contentArray				= [[NSArray alloc] init];
		selectionIndexes			= [[NSMutableIndexSet alloc] init];
		dragHoverIndex				= NSNotFound;
		accumulatedKeyStrokes		= [[NSString alloc] init];
		numberOfPreRenderedRows		= 3;
		layoutManager				= [[BCCollectionViewLayoutManager alloc] initWithCollectionView:self];
		visibleGroupViewControllers = [[NSMutableDictionary alloc] init];
		//[self addObserver:self forKeyPath:@"backgroundColor" options:0 context:NULL];
		_border = 10;
//		NSClipView *enclosingClipView = [[self enclosingScrollView] contentView];
//		[enclosingClipView setPostsBoundsChangedNotifications:YES];
//		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
//		[center addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:enclosingClipView];
//		[center addObserver:self selector:@selector(viewDidResize) name:NSViewFrameDidChangeNotification object:self];
	}
	return self;
}
- (void) awakeFromNib {
	//UKLog(@"__");
	[super awakeFromNib];
}

- (void) bind:(NSString *)binding
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	//UKLog(@"keyPath: %@", keyPath );
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
			//UKLog(@"= %d newSelectionIndex: %@", _updateing, newSelectionIndex);
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
		if ([keyPath isEqualToString:@"backgroundColor"])
			[self setNeedsDisplay:YES];
		else if ([keyPath isEqual:zoomValueObserverKey]) {
			if ([self respondsToSelector:@selector(zoomValueDidChange)])
				[self performSelector:@selector(zoomValueDidChange)];
		}
		else if ([keyPath isEqualToString:@"isCollapsed"]) {
			[self softReloadDataWithCompletionBlock:^{
				[self performSelector:@selector(scrollViewDidScroll:)];
			}];
		} 
		else
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
	
	//NSLog(@"GSSegmentedControl:observeValueForKeyPath:ende" );
	//[self setNeedsDisplay:YES];
}

- (void) dealloc
{
	//[self removeObserver:self forKeyPath:@"backgroundColor"];
	//[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:zoomValueObserverKey];
	delegate = nil;
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center removeObserver:self name:NSViewBoundsDidChangeNotification object:[[self enclosingScrollView] contentView]];
	[center removeObserver:self name:NSViewFrameDidChangeNotification object:self];
	
//	for (BCCollectionViewGroup *group in groups)
//		[group removeObserver:self forKeyPath:@"isCollapsed"];
	
	[layoutManager release];
	[reusableViewControllers release];
	[visibleViewControllers release];
	[visibleGroupViewControllers release];
	[contentArray release];
	[groups release];
	[selectionIndexes release];
	[originalSelectionIndexes release];
	[accumulatedKeyStrokes release];
	[zoomValueObserverKey release];
	[super dealloc];
}

- (BOOL)isFlipped
{
	return YES;
}

#pragma mark Drawing Selections

- (BOOL)shoulDrawSelections
{
	if ([delegate respondsToSelector:@selector(collectionViewShouldDrawSelections:)])
		return [delegate collectionViewShouldDrawSelections:self];
	else
		return YES;
}

- (BOOL)shoulDrawHover
{
	if ([delegate respondsToSelector:@selector(collectionViewShouldDrawHover:)])
		return [delegate collectionViewShouldDrawHover:self];
	else
		return YES;
}

- (void) drawItemSelectionForInRect:(NSRect)aRect {
	NSRect insetRect = NSInsetRect(aRect, 1, 1);
	if ([self needsToDrawRect:insetRect]) {
		[[NSColor lightGrayColor] set];
		[[NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:10 yRadius:10] fill];
	}
}

- (void) drawRect:(NSRect)dirtyRect
{
	NSRect VisibleRect = [self visibleRect];
	if ([[self window] isMainWindow]) {
		[[NSColor colorWithDeviceWhite:0.4f alpha:1] set];
	}
	else {
		[[NSColor lightGrayColor] set];
	}
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
	
	NSBezierPath * BezierPath = [[NSBezierPath alloc] init];
	NSUInteger LastVerticalOffset = NSNotFound;
	NSInteger VerticalOffset;
	for (NSNumber* GoupeIndex in VisibleIndexes) {
		
		NSUInteger Index = [GoupeIndex integerValue];
		NSViewController * Group = [visibleGroupViewControllers objectForKey:GoupeIndex];
		if (Index > 0 && LastVerticalOffset == NSNotFound ) {
			LastVerticalOffset = NSMinY(VisibleRect) - (_border * 0.5f);
		}
		VerticalOffset = NSMinY([[Group view] frame]) + (_border * 0.5f);
		if (VerticalOffset - 4 > LastVerticalOffset && LastVerticalOffset < NSNotFound) {
			NSRect GroupFrame = NSMakeRect(_border * 0.5f , LastVerticalOffset, VisibleRect.size.width - _border, VerticalOffset - LastVerticalOffset - 4);
			//[BezierPath appendBezierPathWithRoundedRect:GroupFrame xRadius:3 yRadius:3];
			//[BezierPath appendBezierPathWithRect:GroupFrame];
			NSRectFill(GroupFrame);
		}
		LastVerticalOffset = VerticalOffset;
	}
	if (LastVerticalOffset == NSNotFound ) {
		if ( [groups count] > 0) {
			LastVerticalOffset = NSMinY(VisibleRect) - 7;
		}
		else {
			LastVerticalOffset = (_border * 0.5f);
		}
	}
	BCCollectionViewLayoutItem *layoutItem = [[layoutManager itemLayouts] lastObject];
	VerticalOffset = NSMaxY([layoutItem itemRect]) + 4;
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
	[Shadow release];
	[[NSColor grayColor] set];
	NSFrameRect(BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation));
}

#pragma mark Delegate Call Wrappers

- (void)delegateUpdateSelectionForItemAtIndex:(NSUInteger)index
{
	if (index < [contentArray count] && [delegate respondsToSelector:@selector(collectionView:updateViewControllerAsSelected:forItem:)])
		[delegate collectionView:self updateViewControllerAsSelected:[self viewControllerForItemAtIndex:index]
							 forItem:[contentArray objectAtIndex:index]];
}

- (void)delegateUpdateDeselectionForItemAtIndex:(NSUInteger)index
{
	
	if ( index < [contentArray count] && [delegate respondsToSelector:@selector(collectionView:updateViewControllerAsDeselected:forItem:)])
		[delegate collectionView:self updateViewControllerAsDeselected:[self viewControllerForItemAtIndex:index]
							 forItem:[contentArray objectAtIndex:index]];
}

- (void) delegateCollectionViewSelectionDidChange {
	if (!selectionChangedDisabled) {
		_updateing = YES;
		[(NSArrayController*)_observedObjectForSelectionIndexes setSelectionIndexes:selectionIndexes];
		_updateing = NO;
	}
	if (!selectionChangedDisabled && [delegate respondsToSelector:@selector(collectionViewSelectionDidChange:)]) {
		[[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(collectionViewSelectionDidChange:) target:delegate argument:self];
		[(id)delegate performSelector:@selector(collectionViewSelectionDidChange:) withObject:self afterDelay:0.0];
	}
}

- (void)delegateDidSelectItemAtIndex:(NSUInteger)index
{
	if ([delegate respondsToSelector:@selector(collectionView:didSelectItem:withViewController:)])
		[delegate collectionView:self
				   didSelectItem:[contentArray objectAtIndex:index]
			  withViewController:[self viewControllerForItemAtIndex:index]];
}

- (void)delegateDidDeselectItemAtIndex:(NSUInteger)index
{
	if ([delegate respondsToSelector:@selector(collectionView:didDeselectItem:withViewController:)])
		[delegate collectionView:self
			 didDeselectItem:[contentArray objectAtIndex:index]
		withViewController:[self viewControllerForItemAtIndex:index]];
}

- (void)delegateViewControllerBecameInvisibleAtIndex:(NSUInteger)index
{
	if ([delegate respondsToSelector:@selector(collectionView:viewControllerBecameInvisible:)])
		[delegate collectionView:self viewControllerBecameInvisible:[self viewControllerForItemAtIndex:index]];
}

- (NSSize)cellSize
{
	return [delegate cellSizeForCollectionView:self];
}

- (NSUInteger)groupHeaderHeight
{
	return [delegate groupHeaderHeightForCollectionView:self];
}

- (NSIndexSet *)indexesOfItemsInRect:(NSRect)aRect
{
	NSArray *itemLayouts = [layoutManager itemLayouts];
	NSIndexSet *visibleIndexes = [itemLayouts indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id itemLayout, NSUInteger idx, BOOL *stop) {
		return NSIntersectsRect([itemLayout itemRect], aRect);
	}];
	return visibleIndexes;
}

- (NSIndexSet *)indexesOfItemContentRectsInRect:(NSRect)aRect
{
	NSArray *itemLayouts = [layoutManager itemLayouts];
	NSIndexSet *visibleIndexes = [itemLayouts indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id itemLayout, NSUInteger idx, BOOL *stop) {
		return NSIntersectsRect([itemLayout itemRect], aRect);
	}];
	return visibleIndexes;
}

- (NSRange)rangeOfVisibleItems
{
	NSIndexSet *visibleIndexes = [self indexesOfItemsInRect:[self visibleRect]];
	return NSMakeRange([visibleIndexes firstIndex], [visibleIndexes lastIndex]-[visibleIndexes firstIndex]);
}

- (NSRange)rangeOfVisibleItemsWithOverflow
{
	NSRange range = [self rangeOfVisibleItems];
	NSInteger extraItems = [layoutManager maximumNumberOfItemsPerRow] * numberOfPreRenderedRows;
	NSInteger min = range.location;
	NSInteger max = range.location + range.length;
	
	min = MAX(0, min-extraItems);
	max = MIN([contentArray count], max+extraItems);
	return NSMakeRange(min, max-min);
}

#pragma mark Querying ViewControllers

- (NSIndexSet *)indexesOfViewControllers
{
	NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
	for (NSNumber *number in [visibleViewControllers allKeys])
		[set addIndex:[number integerValue]];
	return set;
}

- (NSArray *)visibleViewControllerArray
{
	return [visibleViewControllers allValues];
}

- (NSIndexSet *)indexesOfInvisibleViewControllers
{
	NSRange visibleRange = [self rangeOfVisibleItemsWithOverflow];
	return [[self indexesOfViewControllers] indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
		return !NSLocationInRange(idx, visibleRange);
	}];
}

- (NSViewController *)viewControllerForItemAtIndex:(NSUInteger)index
{
	return [visibleViewControllers objectForKey:[NSNumber numberWithInteger:index]];
}

#pragma mark Swapping ViewControllers in and out

- (void)removeViewControllerForItemAtIndex:(NSUInteger)anIndex
{
	NSNumber *key = [NSNumber numberWithInteger:anIndex];
	NSViewController *viewController = [visibleViewControllers objectForKey:key];
	
	//[[viewController view] removeFromSuperview];
	[self delegateUpdateDeselectionForItemAtIndex:anIndex];
	[self delegateViewControllerBecameInvisibleAtIndex:anIndex];

	[viewController setRepresentedObject:nil];
	[[viewController view] setFrameOrigin:NSMakePoint(-1000, 200)];
	
	
	[reusableViewControllers addObject:viewController];
	[visibleViewControllers removeObjectForKey:key];
}


- (void)removeInvisibleViewControllers
{
	[[self indexesOfInvisibleViewControllers] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[self removeViewControllerForItemAtIndex:idx];
	}];
}

- (NSViewController *)emptyViewControllerForInsertion
{
	if ([reusableViewControllers count] > 0) {
		NSViewController *viewController = [[[reusableViewControllers lastObject] retain] autorelease];
		[reusableViewControllers removeLastObject];
		return viewController;
	} else
		return [delegate reusableViewControllerForCollectionView:self];
}

- (void)addMissingViewControllerForItemAtIndex:(NSUInteger)anIndex withFrame:(NSRect)aRect
{
	if (anIndex < [contentArray count]) {
		NSViewController *viewController = [self emptyViewControllerForInsertion];
		[visibleViewControllers setObject:viewController forKey:[NSNumber numberWithInteger:anIndex]];
		[[viewController view] setFrame:aRect];
		[[viewController view] setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin];
		
		id itemToLoad = [contentArray objectAtIndex:anIndex];
		[delegate collectionView:self willShowViewController:viewController forItem:itemToLoad];
		if ([[viewController view] superview] != self) {
			[self addSubview:[viewController view]];
		}
		if ([selectionIndexes containsIndex:anIndex])
			[self delegateUpdateSelectionForItemAtIndex:anIndex];
	}
}

- (void)addMissingGroupHeaders
{
	NSMutableArray * NotNeededGroucontrollers = [NSMutableArray arrayWithArray:[visibleGroupViewControllers allKeys]];
	if ([groups count] > 0) {
		[groups enumerateObjectsUsingBlock:^(id group, NSUInteger idx, BOOL *stop) {
			NSRect groupRect = NSMakeRect(0, NSMinY([layoutManager rectOfItemAtIndex:[group itemRange].location])-[self groupHeaderHeight], NSWidth([self visibleRect]), [self groupHeaderHeight]);
			if (idx == 0 && ![group isCollapsed] && [delegate respondsToSelector:@selector(topOffsetForItemsInCollectionView:)])
				groupRect.origin.y -= [delegate topOffsetForItemsInCollectionView:self];
			
			BOOL groupShouldBeVisible = NSIntersectsRect(groupRect, [self visibleRect]);
			NSViewController *groupViewController = [visibleGroupViewControllers objectForKey:[NSNumber numberWithInteger:idx]];
			if (groupShouldBeVisible) {
				if (!groupViewController) {
					groupViewController = [delegate collectionView:self headerForGroup:group];
					[self addSubview:[groupViewController view]];
					[visibleGroupViewControllers setObject:groupViewController forKey:[NSNumber numberWithInteger:idx]];
				}
				[delegate collectionView:self willShowGroupHeader:groupViewController forGroup:group];
				[NotNeededGroucontrollers removeObject:[NSNumber numberWithInteger:idx]];
				[[groupViewController view] setFrame:groupRect];
				[[groupViewController view] setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin];
			}
			else if (groupViewController) {
				[[groupViewController view] removeFromSuperview];
				[visibleGroupViewControllers removeObjectForKey:[NSNumber numberWithInteger:idx]];
			}
		}];
		for (NSNumber * Key in NotNeededGroucontrollers) {
			NSViewController * groupViewController = [visibleGroupViewControllers objectForKey:Key];
			[[groupViewController view] removeFromSuperview];
			[visibleGroupViewControllers removeObjectForKey:Key];
		}
	}
	else {
		for (NSViewController *viewController in [visibleGroupViewControllers allValues])
			[[viewController view] removeFromSuperview];
		[visibleGroupViewControllers removeAllObjects];
	}
}

- (void)addMissingViewControllersToView
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSIndexSet indexSetWithIndexesInRange:[self rangeOfVisibleItemsWithOverflow]] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			if (![visibleViewControllers objectForKey:[NSNumber numberWithInteger:idx]]) {
				[self addMissingViewControllerForItemAtIndex:idx withFrame:[layoutManager rectOfItemAtIndex:idx]];
			}
		}];
		[self addMissingGroupHeaders];
	});
}
/*
- (void)moveViewControllersToProperPosition {
	if(animated)
    {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.1];
    }	
	for (NSNumber *number in visibleViewControllers) {
		NSRect rect = [layoutManager rectOfItemAtIndex:[number integerValue]];
		if (!NSEqualRects(rect, NSZeroRect)) {
			if(animated)
				[[[[visibleViewControllers objectForKey:number] view] animator] setFrame:rect];
			else
				[[[visibleViewControllers objectForKey:number] view] setFrame:rect];
		}
	}
	if(animated)
        [NSAnimationContext endGrouping];
	// there is sometimes a redraw problem if the contentarray is change. This reduces the likelihood, 
	// but does not solve the problem
	[self setNeedsDisplay:YES]; 
}
*/
#pragma mark Selecting and Deselecting Items

- (void)selectItemAtIndex:(NSUInteger)index
{
	[self selectItemAtIndex:index inBulk:NO];
}

- (void)selectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulkSelecting
{
	if (index >= [contentArray count])
		return;
		
	BOOL maySelectItem = YES;
	NSViewController *viewController = [self viewControllerForItemAtIndex:index];
	id item = [contentArray objectAtIndex:index];
	
	if ([delegate respondsToSelector:@selector(collectionView:shouldSelectItem:withViewController:)])
		maySelectItem = [delegate collectionView:self shouldSelectItem:item withViewController:viewController];
	
	if (maySelectItem) {
		[selectionIndexes addIndex:index];
		//[self delegateUpdateSelectionForItemAtIndex:index];
		//[self delegateDidSelectItemAtIndex:index];
		if (!bulkSelecting)
			[self delegateCollectionViewSelectionDidChange];
		if ([self shoulDrawSelections]) {
			//UKLog(@"__ ");
			[self setNeedsDisplayInRect:[layoutManager rectOfItemAtIndex:index]];
		}
	}
	
	if (!bulkSelecting)
		lastSelectionIndex = index;
}

- (void)selectItemsAtIndexes:(NSIndexSet *)indexes
{
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[self selectItemAtIndex:idx inBulk:YES];
	}];
	lastSelectionIndex = [indexes firstIndex];
	[self delegateCollectionViewSelectionDidChange];
}

- (void)deselectItemAtIndex:(NSUInteger)index
{
	[self deselectItemAtIndex:index inBulk:NO];
}

- (void)deselectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulkDeselecting
{
	if (index < [contentArray count]) {
		[selectionIndexes removeIndex:index];
//		if ([self shoulDrawSelections]) {
//			UKLog(@"__");
//			[self setNeedsDisplayInRect:[layoutManager rectOfItemAtIndex:index]];
//		}
//		
		if (!bulkDeselecting)
			[self delegateCollectionViewSelectionDidChange];
//		[self delegateDidDeselectItemAtIndex:index];
//		[self delegateUpdateDeselectionForItemAtIndex:index];
	}
}

- (void)deselectItemsAtIndexes:(NSIndexSet *)indexes
{
	if ([indexes count] > 0) {
		[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[self deselectItemAtIndex:idx inBulk:YES];
		}];
		[self delegateCollectionViewSelectionDidChange];
	}
}

- (void)deselectAllItems
{
	[self deselectItemsAtIndexes:selectionIndexes];
}

- (NSIndexSet *)selectionIndexes
{
	return selectionIndexes;
}

- (void)selectAll:(id)sender
{
	[self selectItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[contentArray count])]];
}

#pragma mark User-interaction

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)canBecomeKeyView
{
	return YES;
}

#pragma mark Reloading and Updating the Icon View

- (void)softReloadVisibleViewControllers
{
	NSMutableArray *removeKeys = [NSMutableArray array];
	//UKLog(@"__ selectionIndexes: %@", selectionIndexes);
	for (NSString *number in visibleViewControllers) {
		NSUInteger index = [number integerValue];
		NSViewController *controller = [visibleViewControllers objectForKey:number];
		
		if (index < [contentArray count]) {
			[delegate collectionView:self willShowViewController:controller forItem:[contentArray objectAtIndex:index]];
		} else {
			[self delegateViewControllerBecameInvisibleAtIndex:index];
			[[controller view] setFrameOrigin:NSMakePoint(-1000, 200)];
			[reusableViewControllers addObject:controller];
			[removeKeys addObject:number];
		}
	}
	[visibleViewControllers removeObjectsForKeys:removeKeys];
}

- (void)resizeFrameToFitContents
{
	NSRect frame = [self frame];
	frame.size.height = [self visibleRect].size.height;
	if ([contentArray count] > 0) {
		BCCollectionViewLayoutItem *layoutItem = [[layoutManager itemLayouts] lastObject];
		frame.size.height = MAX(frame.size.height, NSMaxY([layoutItem itemRect]) + (_border / 2));
	}
	[self setFrame:frame];
}

- (void)reloadDataWithItems:(NSArray *)newContent emptyCaches:(BOOL)shouldEmptyCaches
{
	[self reloadDataWithItems:newContent groups:nil emptyCaches:shouldEmptyCaches];
}

- (void)reloadDataWithItems:(NSArray *)newContent groups:(NSArray *)newGroups emptyCaches:(BOOL)shouldEmptyCaches
{
	[self reloadDataWithItems:newContent groups:newGroups emptyCaches:shouldEmptyCaches completionBlock:^{}];
}

- (void)reloadDataWithItems:(NSArray *)newContent groups:(NSArray *)newGroups emptyCaches:(BOOL)shouldEmptyCaches completionBlock:(dispatch_block_t)completionBlock
{
	//[self deselectAllItems];
	[layoutManager cancelItemEnumerator];
	
	if (!delegate)
		return;
	
	NSSize cellSize = [delegate cellSizeForCollectionView:self];
	if (NSWidth([self frame]) < cellSize.width || NSHeight([self frame]) < cellSize.height)
		return;
	// some notification info was leaking, need to reanable the functionality later.
//	for (BCCollectionViewGroup *group in groups)
//		[group removeObserver:self forKeyPath:@"isCollapsed"];
//	for (BCCollectionViewGroup *group in newGroups)
//		[group addObserver:self forKeyPath:@"isCollapsed" options:0 context:NULL];
	
	self.groups			 = newGroups;
	self.contentArray = newContent;
	
//	for (NSViewController *viewController in [visibleGroupViewControllers allValues])
//		[[viewController view] removeFromSuperview];
//	[visibleGroupViewControllers removeAllObjects];
	
	if (shouldEmptyCaches) {
		for (NSViewController *viewController in [visibleViewControllers allValues]) {
			[[viewController view] removeFromSuperview];
			if ([delegate respondsToSelector:@selector(collectionView:viewControllerBecameInvisible:)])
				[delegate collectionView:self viewControllerBecameInvisible:viewController];
		}
		
		[reusableViewControllers removeAllObjects];
		[visibleViewControllers removeAllObjects];
	} else
		[self softReloadVisibleViewControllers];
	
	//[selectionIndexes removeAllIndexes];
	
	NSRect visibleRect = [self visibleRect];
	[layoutManager enumerateItems:^(BCCollectionViewLayoutItem *layoutItem) {
		NSViewController *viewController = [self viewControllerForItemAtIndex:[layoutItem itemIndex]];
		if (viewController) {
			[[viewController view] setFrame:[layoutItem itemRect]];
			[delegate collectionView:self willShowViewController:viewController forItem:[contentArray objectAtIndex:[layoutItem itemIndex]]];
		} else if (NSIntersectsRect(visibleRect, [layoutItem itemRect]))
			[self addMissingViewControllerForItemAtIndex:[layoutItem itemIndex] withFrame:[layoutItem itemRect]];
	} completionBlock:^{
		[self resizeFrameToFitContents];
		[self addMissingGroupHeaders];
		dispatch_async(dispatch_get_main_queue(), completionBlock);
		//UKLog(@"__reloadDataWithItems");
		[self setNeedsDisplay:YES];
	}];
}

- (void) scrollViewDidScroll:(NSNotification *)note
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self removeInvisibleViewControllers];
		[self addMissingViewControllersToView];
	});
	
	if ([delegate respondsToSelector:@selector(collectionViewDidScroll:inDirection:)]) {
		if ([self visibleRect].origin.y > previousFrameBounds.origin.y)
			[delegate collectionViewDidScroll:self inDirection:BCCollectionViewScrollDirectionDown];
		else
			[delegate collectionViewDidScroll:self inDirection:BCCollectionViewScrollDirectionUp];
		previousFrameBounds = [self visibleRect];
	}
}

- (void) viewDidResize
{
	if ([contentArray count] > 0 && [visibleViewControllers count] > 0)
		[self softReloadDataWithCompletionBlock:NULL];
}

- (void)softReloadDataWithCompletionBlock:(dispatch_block_t)block
{
	NSSize cellSize = [delegate cellSizeForCollectionView:self];
	if (NSWidth([self visibleRect]) < cellSize.width || NSHeight([self visibleRect]) < cellSize.height)
		return;
	
	NSRange range = [self rangeOfVisibleItemsWithOverflow];
	[layoutManager enumerateItems:^(BCCollectionViewLayoutItem *layoutItem) {
		if (NSLocationInRange([layoutItem itemIndex], range)) {
			NSViewController *controller = [self viewControllerForItemAtIndex:[layoutItem itemIndex]];
			if (controller)
				[[controller view] setFrame:[layoutItem itemRect]];
			else
				[self addMissingViewControllerForItemAtIndex:[layoutItem itemIndex] withFrame:[layoutItem itemRect]];
		} else {
			if ([self viewControllerForItemAtIndex:[layoutItem itemIndex]])
				[self removeViewControllerForItemAtIndex:[layoutItem itemIndex]];
		}
	} completionBlock:^(void) {
		[self resizeFrameToFitContents];
		[self addMissingGroupHeaders];
		[self setNeedsDisplay:YES];
		if (block != NULL)
			block();
	}];
}

- (NSMenu *) menuForEvent:(NSEvent *)anEvent
{
	[self mouseDown:anEvent];
	
	if ([delegate respondsToSelector:@selector(collectionView:menuForItemsAtIndexes:)])
		return [delegate collectionView:self menuForItemsAtIndexes:[self selectionIndexes]];
	else
		return nil;
}

- (BOOL)resignFirstResponder
{
	if ([delegate respondsToSelector:@selector(collectionViewLostFirstResponder:)])
		[delegate collectionViewLostFirstResponder:self];
	[self setNeedsDisplay:YES];
	return [super resignFirstResponder];
}

- (BOOL)becomeFirstResponder
{
	if ([delegate respondsToSelector:@selector(collectionViewBecameFirstResponder:)])
		[delegate collectionViewBecameFirstResponder:self];
	[self setNeedsDisplay:YES];
	return [super becomeFirstResponder];
}

- (BOOL)isOpaque
{
	return YES;
}

@end
