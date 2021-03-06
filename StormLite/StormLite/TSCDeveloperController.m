//
//  TSCDeveloperController.m
//  ThunderStorm
//
//  Created by Matt Cheetham on 14/01/2014.
//  Copyright (c) 2014 3 SIDED CUBE. All rights reserved.
//

#define API_VERSION [[NSBundle mainBundle] infoDictionary][@"TSCAPIVersion"]
#define API_BASEURL [[NSBundle mainBundle] infoDictionary][@"TSCBaseURL"]
#define API_APPID [[NSBundle mainBundle] infoDictionary][@"TSCAppId"]
#define BUGS_VERSION [[NSBundle mainBundle] infoDictionary][@"TSCBugsVersion"]
#define BUILD_DATE [[NSBundle mainBundle] infoDictionary][@"TSCBuildDate"]
#define GOOGLE_TRACKING_ID [[NSBundle mainBundle] infoDictionary][@"TSCGoogleTrackingId"]
#define STATS_VERSION [[NSBundle mainBundle] infoDictionary][@"TSCStatsVersion"]
#define STORM_TRACKING_ID [[NSBundle mainBundle] infoDictionary][@"TSCTrackingId"]
#define DEVELOPER_MODE [[NSUserDefaults standardUserDefaults] boolForKey:@"developer_mode_enabled"]

#import "TSCDeveloperController.h"
#import "TSCAuthenticationController.h"
#import "PCHUDActivityView.h"
#import "TSCContentController.h"
#import "TSCStormLanguageController.h"
#import "TSCRequestController.h"

@interface TSCDeveloperController ()

@property (nonatomic, strong) UIWindow *appWindow;
@property (nonatomic, strong) TSCDefaultTheme *currentTheme;
@property (nonatomic) SEL overrideSelector;
@property (nonatomic, strong) id overrideTarget;

@end

@implementation TSCDeveloperController

static TSCDeveloperController *sharedController = nil;

+ (TSCDeveloperController *)sharedController
{
    @synchronized(self) {
        if (sharedController == nil) {
            sharedController = [[self alloc] init];
        }
    }
    return sharedController;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TSCAuthenticationCredentialsSet" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TSCAuthenticationFailed" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TSCModeSwitchingComplete" object:nil];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/apps/%@/update", API_BASEURL, @"latest", API_APPID]];
        
        //Setup request kit
        self.requestController = [[TSCRequestController alloc] initWithBaseURL:self.baseURL];
        
    }
    return self;
}

- (void)installDeveloperModeToWindow:(UIWindow *)window currentTheme:(TSCDefaultTheme *)currentTheme
{
    self.appWindow = window;
    self.currentTheme = currentTheme;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modeSwitchingComplete) name:@"TSCModeSwitchingComplete" object:nil];
}

- (void)overrideRefreshTarget:(id)target selector:(SEL)selector
{
    self.overrideTarget = target;
    self.overrideSelector = selector;
}

- (void)modeSwitchingComplete
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [PCHUDActivityView finishInView:self.appWindow];
        
        UIViewAnimationOptions option;
        if([TSCDeveloperController isDevMode]){
            option = UIViewAnimationOptionTransitionCurlUp;
        } else {
            option = UIViewAnimationOptionTransitionCurlDown;
        }
        
        if (self.overrideTarget) {
            
            IMP imp = [self.overrideTarget methodForSelector:self.overrideSelector];
            void (*func)(id, SEL) = (void *)imp;
            func(self.overrideTarget, self.overrideSelector);
            
        }
    }];
}

- (void)appResumedFromBackground
{
    // Dev mode?
    if(DEVELOPER_MODE){
        NSLog(@"Dev mode enabled");
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TSCAuthenticationCredentialsSet" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TSCAuthenticationFailed" object:nil];
        [self loginToDevMode];
    }
    
    if(!DEVELOPER_MODE && [TSCDeveloperController isDevMode]){
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TSCAuthenticationCredentialsSet" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TSCAuthenticationFailed" object:nil];
        [self switchToLiveMode];
        
    }
    
    if(![[TSCContentController sharedController] isCheckingForUpdates]) {
        [[TSCContentController sharedController] checkForUpdates];
    }
}

- (void)loginToDevMode
{
    if(![TSCDeveloperController isDevMode]){
        UIAlertView *editNumberAlert = [[UIAlertView alloc] initWithTitle:@"Developer mode enabled" message:@"Please log in with your Storm account " delegate:self cancelButtonTitle:@"Disable" otherButtonTitles:@"Login", nil];
        editNumberAlert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        editNumberAlert.tag = 0;
        
        [editNumberAlert show];
    }
}

- (void)switchToDevMode {
    
    NSLog(@"<Developer Controls> Switching to dev mode");
    
    NSLog(@"<Developer Controls> Clearing cache");
    
    [[TSCContentController sharedController] TSC_cleanoutCache];
    
    [[TSCContentController sharedController] downloadUpdatePackageFromURL:[NSString stringWithFormat:@"%@/%@/apps/%@/bundle?&density=%@&environment=test", API_BASEURL, API_VERSION, API_APPID, @"x2"]];
    
}

- (void)switchToLiveMode {
    
    NSLog(@"<Developer Controls> Switching to live mode");
    
    NSLog(@"<Developer Controls> Clearing cache");
    
    [[TSCContentController sharedController] TSC_cleanoutCache];
    [[TSCStormLanguageController sharedController] reloadLanguagePack];
    [[TSCContentController sharedController] TSC_updateSettingsBundle];
    [[TSCContentController sharedController] checkForUpdates];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TSCAuthenticationToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TSCModeSwitchingComplete" object:nil];
}

+ (BOOL)isDevMode
{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"TSCAuthenticationToken"]){
        return YES;
    }
    
    return NO;
}

#pragma mark - UIAlertView delegate


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if(alertView.tag == 0 && buttonIndex == 1){
        
        NSString *username = [alertView textFieldAtIndex:0].text;
        NSString *password = [alertView textFieldAtIndex:1].text;
        
        [[TSCAuthenticationController sharedInstance] authenticateUsername:username password:password];
        
        [PCHUDActivityView startInView:[[UIApplication sharedApplication] windows][0]];
        
    } else {
        
        if([TSCDeveloperController isDevMode]){
            [self switchToLiveMode];
        } else {

            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"developer_mode_enabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }
    }
}

@end
