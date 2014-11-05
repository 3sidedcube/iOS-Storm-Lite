//
//  TSCLocalisedObject.h
//  StormLite
//
//  Created by Simon Mitchell on 05/11/2014.
//  Copyright (c) 2014 Sam Houghton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (AddedProperties)

- (id)associativeObjectForKey: (NSString *)key;
- (void)setAssociativeObject: (id)object forKey: (NSString *)key;

@end
