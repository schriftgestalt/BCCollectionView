//
//  GSCollectionView.h
//  Glyphs Mini
//
//  Created by Georg Seifert on 17.12.11.
//  Copyright 2011 schriftgestaltung.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BCCollectionView.h"

@interface GSCollectionView : BCCollectionView {
	BOOL didProcessEvent;
	
	id _observedObjectForContentArray;
	NSString *_observedKeyPathForContentArray;
	BOOL _badSelectionForContentArray;
	
	id _observedObjectForSelectionIndexes;
	NSString *_observedKeyPathForSelectionIndexes;
	BOOL _badSelectionForSelectionIndexes;
	
	BOOL _updateing;
}

@end
