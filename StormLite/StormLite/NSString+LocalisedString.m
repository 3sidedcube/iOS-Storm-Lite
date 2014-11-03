//
//  NSString+LocalisedString.m
//  ThunderCloud
//
//  Created by Matthew Cheetham on 16/09/2014.
//  Copyright (c) 2014 threesidedcube. All rights reserved.
//

#import "NSString+LocalisedString.h"
#import <objc/runtime.h>
#import "TSCThunderBasics.h"

@interface NSString (LocalisedStringPrivate)

@property (nonatomic, strong, readwrite) NSString *localisationKey;

@end

@implementation NSString (LocalisedString)

+ (instancetype)stringWithLocalisationKey:(NSString *)key
{
    NSString *string = TSCLanguageString(key);
    string.localisationKey = key;
    
    return string;
}

#pragma mark - setters/getters

- (NSString *)localisationKey
{
    return objc_getAssociatedObject(self, @selector(localisationKey));
}

- (void)setLocalisationKey:(NSString *)localisationKey
{
    objc_setAssociatedObject(self, @selector(localisationKey), localisationKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
