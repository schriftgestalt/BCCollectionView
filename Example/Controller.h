//
//  Controller.h
//  Example
//
//  Created by Aaron Brethorst on 5/3/11.
//  Copyright 2011 Structlab LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BCCollectionView.h"

@interface Controller : NSObject <BCCollectionViewDelegate>
{
	NSMutableArray *imageContent;
	IBOutlet BCCollectionView *collectionView;
	IBOutlet NSArrayController * imageContentController;
}
@property(nonatomic,retain) NSMutableArray *imageContent;
@end
