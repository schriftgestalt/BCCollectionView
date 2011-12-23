//
//  GSImageCell.m
//  Example
//
//  Created by Georg Seifert on 24.12.11.
//  Copyright 2011 schriftgestaltung.de. All rights reserved.
//

#import "GSImageCell.h"


@implementation GSImageCell
- (void) setObjectValue:(id) Value {
	// should have used a value Transformer for that
	[super setObjectValue:[Value lastObject]];
}
@end
