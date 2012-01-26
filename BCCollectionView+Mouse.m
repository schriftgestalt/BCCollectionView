//  Created by Pieter Omvlee on 25/11/2010.
//  Copyright 2010 Bohemian Coding. All rights reserved.

#import "BCCollectionView+Mouse.h"
#import "BCGeometryExtensions.h"
#import "BCCollectionView+Dragging.h"
#import "BCCollectionViewLayoutManager.h"

@implementation BCCollectionView (BCCollectionView_Mouse)

- (BOOL)shiftOrCommandKeyPressed
{
	return [NSEvent modifierFlags] & NSShiftKeyMask || [NSEvent modifierFlags] & NSCommandKeyMask;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self window] makeFirstResponder:self];
	
	isDragging				= YES;
	mouseDownLocation		= [self convertPoint:[theEvent locationInWindow] fromView:nil];
	mouseDraggedLocation	= mouseDownLocation;
	NSUInteger index		= [layoutManager indexOfItemContentRectAtPoint:mouseDownLocation];
	
//	if (index != NSNotFound && [delegate respondsToSelector:@selector(collectionView:didClickItem:withViewController:)])
//		[delegate collectionView:self didClickItem:[contentArray objectAtIndex:index] withViewController:[visibleViewControllers objectForKey:[NSNumber numberWithInt:index]]];
	
	if ((!([theEvent modifierFlags] & NSShiftKeyMask || [theEvent modifierFlags] & NSCommandKeyMask) || index == NSNotFound) && ![selectionIndexes containsIndex:index]) {
		//[selectionIndexes removeAllIndexes];
		[self deselectAllItems];
	}
	
	self.originalSelectionIndexes = [[selectionIndexes copy] autorelease];
	
	if ([theEvent type] == NSLeftMouseDown && [theEvent clickCount] == 2 && [delegate respondsToSelector:@selector(collectionView:didDoubleClickViewControllerAtIndex:)])
		[delegate collectionView:self didDoubleClickViewControllerAtIndex:[visibleViewControllers objectForKey:[NSNumber numberWithInt:index]]];
	
	if ((([theEvent modifierFlags] & NSShiftKeyMask || [theEvent modifierFlags] & NSCommandKeyMask)) && [self.originalSelectionIndexes containsIndex:index])
		[self deselectItemAtIndex:index];
	else {
		if ([theEvent modifierFlags] & NSCommandKeyMask) {
			if ([self.originalSelectionIndexes containsIndex:index]) {
				[self deselectItemAtIndex:index];
			}
			else {
				[self selectItemAtIndex:index];
			}
		}
		else if ([[self originalSelectionIndexes] count] == 0) {
			[self selectItemAtIndex:index];
			//[selectionIndexes addIndex:index];
		}
		else if ([NSEvent modifierFlags] & NSShiftKeyMask) {
			NSInteger one = [[self originalSelectionIndexes] lastIndex];
			NSInteger two = index;
			
			if (index == NSNotFound)
				return;
			
			if (two > one)
				[self selectItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(MIN(one,two), 1+MAX(one,two)-MIN(one,two))]];
			else
				[self selectItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(MIN(one,two), MAX(one,two)-MIN(one,two))]];
		}
	}
}

- (void)regularMouseDragged:(NSEvent *)anEvent
{
	NSIndexSet *originalSet = [selectionIndexes copy];
	
	selectionChangedDisabled = YES;
	
	//[self deselectAllItems];
	//[selectionIndexes removeAllIndexes];
	NSMutableIndexSet * NewIndexes = [[NSMutableIndexSet alloc] init];
	if ([self shiftOrCommandKeyPressed]) {
		[self.originalSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			//[self selectItemAtIndex:idx];
			[NewIndexes addIndex:idx];
		}];
	}
	[self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
	
	mouseDraggedLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	NSIndexSet *suggestedIndexes = [self indexesOfItemContentRectsInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
	
	if (![self shiftOrCommandKeyPressed]) {
		//NSMutableIndexSet *oldIndexes = [[selectionIndexes mutableCopy] autorelease];
		//[oldIndexes removeIndexes:suggestedIndexes];
		//[NewIndexes removeIndexes:oldIndexes];
		//[self deselectItemsAtIndexes:oldIndexes];
	}
	[NewIndexes addIndexes:suggestedIndexes];
//	[suggestedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
//		if ([self shiftOrCommandKeyPressed]) {
//			if ([originalSelectionIndexes containsIndex:idx]) {
//				[self deselectItemAtIndex:idx];
//			}
//			else
//				[self selectItemAtIndex:idx];
//		} else
//			[self selectItemAtIndex:idx];
//	}];
	
	[self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
	
	selectionChangedDisabled = NO;
	if (![NewIndexes isEqual:originalSet]) {
		selectionIndexes = [NewIndexes retain];
		[self performSelector:@selector(delegateCollectionViewSelectionDidChange)];
	}
	[NewIndexes release];
}

- (void)mouseDragged:(NSEvent *)anEvent
{
	[self autoscroll:anEvent];
	
	if (isDragging) {
		NSUInteger index = [layoutManager indexOfItemContentRectAtPoint:mouseDownLocation];
		if (index != NSNotFound && [selectionIndexes count] > 0 && NO && [self delegateSupportsDragForItemsAtIndexes:selectionIndexes]) {
			NSPoint mouse = [self convertPoint:[anEvent locationInWindow] fromView:nil];
			CGFloat distance = sqrt(pow(mouse.x-mouseDownLocation.x,2)+pow(mouse.y-mouseDownLocation.y,2));
			if (distance > 3)
				[self initiateDraggingSessionWithEvent:anEvent];
		} else
			[self regularMouseDragged:anEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
	
	mouseDownLocation		= NSZeroPoint;
	mouseDraggedLocation = NSZeroPoint;
	
	isDragging = NO;
	self.originalSelectionIndexes = nil;
}

@end
