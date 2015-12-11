#import "ViewController.h"
#import "focusmotion/sdk/focusmotion.h"
#import "focusmotion/sdk-objc/config.h"
#import "focusmotion/sdk-objc/device.h"
#import "focusmotion/sdk-objc/movementanalyzer.h"
#import "focusmotion/sdk-objc/analyzertrainer.h"
#import "focusmotion/sdk-objc/analyzerresult.h"
#import "focusmotion-pebble/sdk-objc/pebbledevice.h"
#import "focusmotion-applewatch/sdk-objc/applewatchdevice.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *trainButton;
@property (weak, nonatomic) IBOutlet UILabel *dataSetsLabel;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UILabel *resultsLabel;

@end

@implementation ViewController
{
    FmDevice* m_device;
    FmDeviceOutput* m_output;
    FmAnalyzerTrainer* m_trainer;
}

- (void) viewDidLoad
{
    // initialize FocusMotion SDK
    FmConfig config;
    FmConfigInit(&config);
    
    // This is your API key; keep it secret!
    if (!FmInit(&config, "2lIC6lPcPAVNdpq4kvKhUpACobirYB4z"))
    {
        NSAssert(NO, @"Could not initialize FocusMotion SDK");
    }
    
    [FmDevice initializeInstance:self];
    [FmAppleWatchDevice initializeInstance:nil];
    
    
    // initialize Pebble support
    // the UUID is for the "simple" Pebble app, defined in fm/src/samples/simple/pebble/appinfo.json
    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"f3fef676-0c23-41b9-8d23-ba225575b9a0"];
    [FmPebbleDevice initializeInstance:myAppUUID];
    
    // create trainer for movement called "demo"
    m_trainer = [[FmAnalyzerTrainer alloc] init:@"demo"];
    
    // initialize the UI
    self.resultsLabel.text = @"";
    [self updateStatusLabel];
    [self updateStartButton];
    [self updateTrainButton];
    [self updateDataSetsLabel];
    
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminate:) name:UIApplicationWillTerminateNotification object:nil];
}

- (void) willTerminate:(NSNotification*)notification
{
    FmShutdown();
}

- (IBAction) startButtonPressed:(id)sender
{
    if (m_device)
    {
        if (m_device.recording)
        {
            [m_device stopRecording];
        }
        else
        {
            [m_device startRecording];
        }
    }
}

- (IBAction) trainButtonPressed:(id)sender
{
    // train the analyzer with the data we just recorded.
    // NOTE: to simplify the user interface, we are assuming the user always performed 10 reps; in practice,
    // you would probably want the user to enter how many reps he just did.
    [m_trainer addTrainingDataSet:m_output repCount:10];
    [m_trainer train];
    
    m_output = nil;
    
    [self updateTrainButton];
    [self updateDataSetsLabel];
}

- (IBAction) clearButtonPressed:(id)sender
{
    [m_trainer reset];
    [self updateDataSetsLabel];
}

- (void) updateStatusLabel
{
    if (m_device)
    {
        self.statusLabel.text = [NSString stringWithFormat:@"%@: %@", m_device.name, (m_device.connected ? @"connected" : @"disconnected")];
    }
    else
    {
        self.statusLabel.text = @"no available devices";
    }
}

- (void) updateStartButton
{
    if (m_device && m_device.connected)
    {
        self.startButton.enabled = YES;
        
        if (m_device.recording)
        {
            [self.startButton setTitle:@"Stop Recording" forState:UIControlStateNormal];
        }
        else
        {
            [self.startButton setTitle:@"Start Recording" forState:UIControlStateNormal];
        }
    }
    else
    {
        self.startButton.enabled = NO;
    }
}

- (void) updateTrainButton
{
    self.trainButton.enabled = (m_output != nil);
}

- (void) updateDataSetsLabel
{
    self.dataSetsLabel.text = [NSString stringWithFormat:@"Training data sets: %d", m_trainer.numTrainingDataSets];
    self.clearButton.enabled = (m_trainer.numTrainingDataSets > 0);
}

////////////////////////////////////////
// analysis

- (void) analyze
{
    NSLog(@"analyzing...");
    
    // create analyzer for our "demo" analyzer
    FmMovementAnalyzer* analyzer = [FmMovementAnalyzer newTrainedSingleMovementAnalyzer:@"demo"];
    
    // count reps
    [analyzer analyze:m_output];
    
    // update the UI
    if (analyzer.numResults)
    {
        FmAnalyzerResult* result = [analyzer resultAtIndex:0];
        self.resultsLabel.text =
        [NSString stringWithFormat:@
         "  %d reps\n"
         "  duration %.2fs\n"
         "  rep time %.2fs (%.2fs-%.2fs)\n"
         "  variation %.2f\n",
         result.repCount,
         result.duration,
         result.meanRepTime, result.minRepTime, result.maxRepTime,
         result.internalVariation];
    }
    else
    {
        self.resultsLabel.text = @"(no result)";
    }
    
    NSLog(@"...done.");
}


////////////////////////////////////////
// FmDeviceDelegate

- (void) availableChanged:(FmDevice*)device available:(BOOL)available
{
    // We are only supporting Pebble, and at most one Pebble can be paired at a time;
    // so just connect automatically when we detect one.
    if (available)
    {
        m_device = device;
        [m_device connect];
    }
    
    [self updateStatusLabel];
}

- (void) connectedChanged:(FmDevice*)device connected:(BOOL)connected
{
    [self updateStartButton];
    [self updateStatusLabel];
}

- (void) recordingChanged:(FmDevice*)device recording:(BOOL)recording
{
    [self updateStartButton];
    
    if (!recording)
    {
        // just stopped recording
        m_output = m_device.output;
        if (m_trainer.numTrainingDataSets > 0)
        {
            // we have already trained our analyzer; try counting reps.
            [self analyze];
        }
    }
    else
    {
        self.resultsLabel.text = @"";
    }
    
    [self updateTrainButton];
}

- (void) dataReceived:(FmDevice*)device
{
}

- (void) connectionFailed:(FmDevice*)device error:(NSError*)error
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection failed!" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    [self updateStatusLabel];
}

@end
