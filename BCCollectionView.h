//  Created by Pieter Omvlee on 24/11/2010.
//  Copyright 2010 Bohemian Coding. All rights reserved.

#import <Cocoa/Cocoa.h>
#import "BCCollectionViewDelegate.h"

#ifndef BCArray
#define BCArray(args...) [NSArray arrayWithObjects:args, nil]
#endif

@class BCCollectionViewLayoutManager;
@interface BCCollectionView : NSView
{
	IBOutlet id<BCCollectionViewDelegate> delegate;
	BCCollectionViewLayoutManager *layoutManager;

	NSArray *contentArray;
	NSArray *groups;

	NSMutableArray      *reusableViewControllers;
	NSMutableDictionary *visibleViewControllers;
	NSMutableIndexSet   *selectionIndexes;
	NSMutableDictionary *visibleGroupViewControllers;

	NSColor				*backgroundColor;
	NSUInteger			numberOfPreRenderedRows;
	NSUInteger			_border;

	NSPoint				mouseDownLocation;
	NSPoint				mouseDraggedLocation;
	NSInteger			dragHoverIndex;
	BOOL				selectionChangedDisabled;
	NSUInteger			lastSelectionIndex;
@private
	NSRect				previousFrameBounds;
  

	NSIndexSet *		originalSelectionIndexes;
  
	BOOL isDragging;
	BOOL firstDrag;


	NSString *zoomValueObserverKey;
	CGFloat lastPinchMagnification;

	NSString *accumulatedKeyStrokes;
}
@property (nonatomic, assign) id<BCCollectionViewDelegate> delegate;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic) NSUInteger numberOfPreRenderedRows;
@property (nonatomic, assign) NSUInteger border;
//private
@property (nonatomic, copy) NSIndexSet *originalSelectionIndexes;
@property (nonatomic, copy) NSArray *contentArray, *groups;
@property (nonatomic, copy) NSString *zoomValueObserverKey, *accumulatedKeyStrokes;

@property (readonly) NSArray *visibleViewControllerArray;
@property (readonly) BCCollectionViewLayoutManager *layoutManager;

//designated way to load BCCollectionView
- (void)reloadDataWithItems:(NSArray *)newContent emptyCaches:(BOOL)shouldEmptyCaches;
- (void)reloadDataWithItems:(NSArray *)newContent groups:(NSArray *)newGroups emptyCaches:(BOOL)shouldEmptyCaches;
- (void)reloadDataWithItems:(NSArray *)newContent groups:(NSArray *)newGroups emptyCaches:(BOOL)shouldEmptyCaches completionBlock:(dispatch_block_t)completionBlock;

//Managing Selections
- (void)selectItemAtIndex:(NSUInteger)index;
- (void)selectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulk;

- (void)selectItemsAtIndexes:(NSIndexSet *)indexes;
- (void)deselectItemAtIndex:(NSUInteger)index;
- (void)deselectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulk;
- (void)deselectItemsAtIndexes:(NSIndexSet *)indexes;
- (void)deselectAllItems;
- (NSIndexSet *)selectionIndexes;

//Basic Cell Information
- (NSSize)cellSize;
- (NSUInteger)groupHeaderHeight;
- (NSRange)rangeOfVisibleItems;
- (NSRange)rangeOfVisibleItemsWithOverflow;

- (NSIndexSet *)indexesOfItemsInRect:(NSRect)aRect;
- (NSIndexSet *)indexesOfItemContentRectsInRect:(NSRect)aRect;

//Querying ViewControllers
- (NSIndexSet *)indexesOfViewControllers;
- (NSIndexSet *)indexesOfInvisibleViewControllers;
- (NSViewController *)viewControllerForItemAtIndex:(NSUInteger)index;

- (void)softReloadDataWithCompletionBlock:(dispatch_block_t)block;
@end
