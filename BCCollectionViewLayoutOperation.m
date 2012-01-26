//  Created by Pieter Omvlee on 02/03/2011.
//  Copyright 2011 Bohemian Coding. All rights reserved.

#import "BCCollectionViewLayoutOperation.h"
#import "BCCollectionView.h"
#import "BCCollectionViewLayoutItem.h"
#import "BCCollectionViewGroup.h"
#import "BCCollectionViewLayoutManager.h"

@implementation BCCollectionViewLayoutOperation
@synthesize layoutCallBack, collectionView, layoutCompletionBlock;

- (void)main
{
	if ([self isCancelled])
		return;
	NSInteger Border = collectionView.border; 
	NSInteger numberOfRows = 0;
	NSInteger startingX = Border;
	NSInteger x = startingX;
	NSInteger y = 0;
	NSUInteger colIndex   = 0;
	NSRect visibleRect    = [collectionView visibleRect];
	NSRect frame		  = [collectionView frame];
	visibleRect.size.width = frame.size.width; // Visible Rect is sometimes not set properly when lanching.
	UKLog(@"visibleRect: %@", NSStringFromRect(visibleRect));
	NSSize cellSize       = [collectionView cellSize];
	NSSize inset          = NSZeroSize;
	NSInteger maxColumns  = [[collectionView layoutManager] maximumNumberOfItemsPerRow];
	NSUInteger gap        = (NSUInteger)floor((NSWidth(visibleRect) - (2*Border) - (maxColumns*cellSize.width))/maxColumns);
//	if (maxColumns < 4 && maxColumns > 1) {
//		gap = (NSWidth([collectionView frame]) - maxColumns*cellSize.width)/(maxColumns+1);
//		startingX = gap;
//		x = gap;
//	}
	cellSize.width += gap;
//	if ([[collectionView delegate] respondsToSelector:@selector(insetMarginForSelectingItemsInCollectionView:)])
//		inset = [[collectionView delegate] insetMarginForSelectingItemsInCollectionView:collectionView];
	
	NSMutableArray *newLayouts   = [NSMutableArray array];
	NSEnumerator *groupEnum      = [[collectionView groups] objectEnumerator];
	BCCollectionViewGroup *group = [groupEnum nextObject];
	
	if (![group isCollapsed] && [[collectionView delegate] respondsToSelector:@selector(topOffsetForItemsInCollectionView:)])
		y += [[collectionView delegate] topOffsetForItemsInCollectionView:collectionView];
	
	NSUInteger count = [[collectionView contentArray] count];
	for (NSInteger i=0; i<count; i++) {
		if ([self isCancelled])
			return;
		
		if (group && [group itemRange].location == i) {
			if (x != startingX) {
				numberOfRows++;
				colIndex = 0;
				y += cellSize.height;
			}
			y += [collectionView groupHeaderHeight];
			x = startingX;
		}
		BCCollectionViewLayoutItem *item = [BCCollectionViewLayoutItem layoutItem];
		[item setItemIndex:i];
		if (![group isCollapsed]) {
			if (x + cellSize.width + Border > NSMaxX(visibleRect)) {
				numberOfRows++;
				colIndex = 0;
				y += cellSize.height;
				x  = startingX;
			}
			[item setColumnIndex:colIndex];
			[item setItemRect:NSMakeRect(x, y, cellSize.width, cellSize.height)];
			x += cellSize.width; //+ gap;
			colIndex++;
		} else {
			[item setItemRect:NSMakeRect(-cellSize.width*2, y, cellSize.width, cellSize.height)];
		}
		NSRect Frame;
		Frame.size = cellSize;
		Frame.origin = [item itemRect].origin;
		//UKLog(@"__R1: %@ __R2: %@", NSStringFromRect(Frame), NSStringFromRect(NSInsetRect([item itemRect], (CGFloat)roundf(inset.width), (CGFloat)round(inset.height))));
		
		//[item setItemContentRect:NSInsetRect([item itemRect], roundf(inset.width), round(inset.height))];
		[item setItemContentRect:Frame];
		[item setRowIndex:numberOfRows];
		[newLayouts addObject:item];
		
		if (layoutCallBack != nil) {
			dispatch_async(dispatch_get_main_queue(), ^{
				layoutCallBack(item);
			});
		}
		if ([group itemRange].location + [group itemRange].length-1 == i)
			group = [groupEnum nextObject];
	}
	numberOfRows = MAX(numberOfRows, [[collectionView groups] count]);
	if ([[collectionView contentArray] count] > 0 && numberOfRows == -1)
		numberOfRows = 1;
	
	if (![self isCancelled]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[collectionView layoutManager] setItemLayouts:newLayouts];
			layoutCompletionBlock();
		});
	}
}

- (void)dealloc
{
	[layoutCallBack release];
	[layoutCompletionBlock release];
	[super dealloc];
}

@end
