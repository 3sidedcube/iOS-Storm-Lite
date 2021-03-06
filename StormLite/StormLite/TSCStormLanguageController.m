//
//  TSCStormLanguageController.m
//  ThunderCloud
//
//  Created by Matt Cheetham on 04/03/2014.
//  Copyright (c) 2014 3 SIDED CUBE. All rights reserved.
//

#import "TSCStormLanguageController.h"
#import "TSCContentController.h"

@implementation TSCStormLanguageController

static TSCStormLanguageController *sharedController = nil;

+ (TSCStormLanguageController *)sharedController
{
    return sharedController;
}

- (id)init
{
    self = [super initWithDictionary:nil];
    
    if (self) {
        
        self.contentController = [TSCContentController sharedController];
        
        sharedController = self;
    }
    
    return self;
}

#pragma mark - Storm language loading

- (void)reloadLanguagePack
{
    [self loadLanguageFile:[self languageFilePath]];
}

- (NSString *)languageFilePath
{
    // Getting the user locale
    NSLocale *locale = [NSLocale currentLocale];
    
    NSString *localeString = [locale localeIdentifier];
    
    // Re-arranging it to match the language pack filename
    NSArray *localeComponents = [[localeString lowercaseString] componentsSeparatedByString:@"_"];
    
    NSString *language;
    NSString *country;
    
    if (localeComponents && localeComponents.count > 1) {
        language = [localeComponents objectAtIndex:0];
        country = [localeComponents objectAtIndex:1];
    } else {
        NSLog(@"Error getting locale components from %@", localeString);
        return NO;
    }
    
    self.currentLanguage = [NSString stringWithFormat:@"%@_%@", country, language];
    
    /*
     * Load users preferred languages and iterate over each. checking all language packs for similarities and loading the closest match
     */
    NSArray *preferredLanguages = [NSLocale preferredLanguages];
    
    NSArray *availablePacks = [self.contentController filesInDirectory:@"languages"];
    
    NSString *englishFallbackPack = nil;
    
    for (NSString *languageCode in preferredLanguages) {
        
        for (NSString *pack in availablePacks) {
            
            if (!englishFallbackPack && [pack rangeOfString:@"en"].location != NSNotFound) {
                englishFallbackPack = [pack stringByDeletingPathExtension];
            }
            
            if ([pack rangeOfString:languageCode].location != NSNotFound) {
                
                // Found a pack that's similar. Use it.
                self.currentLanguage = [pack stringByDeletingPathExtension];
                return [self.contentController pathForResource:self.currentLanguage ofType:@"json" inDirectory:@"languages"];
                
            }
            
        }
        
    }
    
    if (availablePacks.count > 0) {
        self.currentLanguage = [[availablePacks objectAtIndex:0] stringByDeletingPathExtension];
        return [self.contentController pathForResource:self.currentLanguage ofType:@"json" inDirectory:@"languages"];
    }
    
    // IF this point is reached there are no languages. FAIL.
    
    /* Last ditch attempt at loading a language is to fallback to the first english back possible.. */
    self.currentLanguage = englishFallbackPack;
    return [self.contentController pathForResource:self.currentLanguage ofType:@"json" inDirectory:@"languages"];
    
}

- (void)loadLanguageFile:(NSString *)filePath
{
    if (filePath) {
        
        NSLog(@"<ThunderStorm> [Languages] Loading language at path %@", filePath);
        
        NSError *languageError;
        NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error:&languageError];
        
        if (languageError || !data) {
            
            NSLog(@"<ThunderStorm> [Languages] No data for language pack");
            return;
            
        }
        
        NSDictionary *languageDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        self.languageDictionary = languageDictionary;
        
    } else {
        
        NSLog(@"<ThunderStorm> [Languages] File path was null");
        return;
    }
}


#pragma mark - Locale management

- (NSLocale *)localeForLanguageKey:(NSString *)localeString
{
    NSArray *localeComponents = [localeString componentsSeparatedByString:@"_"];
    
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:[NSLocale localeIdentifierFromComponents:@{NSLocaleLanguageCode: localeComponents[1], NSLocaleCountryCode: localeComponents[0]}]];
    
    return locale;
}

- (NSString *)localisedLanguageNameForLocale:(NSLocale *)locale
{
    return [locale displayNameForKey:NSLocaleIdentifier value:locale.localeIdentifier];
}

- (NSString *)localisedLanguageNameForLocaleIdentifier:(NSString *)localeIdentifier
{
    return [self localisedLanguageNameForLocale:[self localeForLanguageKey:localeIdentifier]];
}

- (NSLocale *)currentLocale
{
    return [self localeForLanguageKey:self.currentLanguage];
}

@end
