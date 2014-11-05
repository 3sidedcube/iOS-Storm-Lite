//
//  TSCStormLanguageController.h
//  ThunderCloud
//
//  Created by Matt Cheetham on 04/03/2014.
//  Copyright (c) 2014 3 SIDED CUBE. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TSCLanguageString(key) [[TSCLanguageController sharedController] stringForKey:(key)]
#define TSCLanguageDictionary(dictionary) [[TSCLanguageController sharedController] stringForDictionary:(dictionary)]

@class TSCContentController;

@interface TSCStormLanguageController : NSObject

@property (nonatomic, strong) NSString *currentLanguage;
@property (nonatomic, strong) NSDictionary *languageDictionary;
@property (nonatomic, strong) NSString *currentLanguageShortKey;
@property (nonatomic, strong) NSString *languagesFolder;
@property (nonatomic, strong) TSCContentController *contentController;

+ (TSCStormLanguageController *)sharedController;
- (void)reloadLanguagePack;
- (NSLocale *)localeForLanguageKey:(NSString *)localeString;
- (NSString *)localisedLanguageNameForLocale:(NSLocale *)locale;
- (NSString *)localisedLanguageNameForLocaleIdentifier:(NSString *)localeIdentifier;
- (NSLocale *)currentLocale;
- (NSString *)stringForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key withFallbackString:(NSString *)fallbackString;
- (NSString *)stringForDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
