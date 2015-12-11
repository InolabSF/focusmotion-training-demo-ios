#import "InterfaceController.h"
#import "focusmotion-applewatch/sdk-objc/localdevice.h"


@interface InterfaceController()

@property IBOutlet WKInterfaceSwitch* recordingSwitch;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.

    [FmLocalDevice instance].deviceDelegate = self;
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction) recordingSwitchChanged:(BOOL)on
{
    if (on)
    {
        [[FmLocalDevice instance] startRecording];
    }
    else
    {
        [[FmLocalDevice instance] stopRecording];
    }
}

////////////////////////////////////////
// FmDeviceDelegate

- (void) availableChanged:(FmLocalDevice*)device available:(BOOL)available
{
    NSLog(@"available: %d", available);
}

- (void) connectedChanged:(FmLocalDevice*)device connected:(BOOL)connected
{
    NSLog(@"connected: %d", connected);
    self.recordingSwitch.hidden = !connected;
}

- (void) recordingChanged:(FmLocalDevice*)device recording:(BOOL)recording
{
    self.recordingSwitch.on = recording;
    [[WKInterfaceDevice currentDevice] playHaptic:(recording?WKHapticTypeStart:WKHapticTypeStop)];
}

- (void) dataSent:(FmLocalDevice*)device
{
}

@end



