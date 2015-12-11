#import "ExtensionDelegate.h"
#import "focusmotion/sdk/focusmotion.h"
#import "focusmotion-applewatch/sdk-objc/localdevice.h"

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching 
{
    FmConfig config;
    FmConfigInit(&config);

    // This is your API key; keep it secret!
    FmInit(&config, "2lIC6lPcPAVNdpq4kvKhUpACobirYB4z");

    [FmLocalDevice initializeInstance];
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

@end
