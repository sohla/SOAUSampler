/*
     File: MainViewController.m
 Abstract: The view controller for this app. Includes all the audio code.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */


#import "MainViewController.h"
#import <AssertMacros.h>

// some MIDI constants:
enum {
	kMIDIMessage_NoteOn    = 0x9,
	kMIDIMessage_NoteOff   = 0x8,
};

#define kLowNote  48
#define kHighNote 72
#define kMidNote  60

//-------------------------------------------------------------
//
//-------------------------------------------------------------


static OSStatus renderCallback(	void *							inRefCon,
							   AudioUnitRenderActionFlags *	ioActionFlags,
							   const AudioTimeStamp *			inTimeStamp,
							   UInt32							inBusNumber,
							   UInt32							inNumberFrames,
							   AudioBufferList *				ioData){
	
    RenderData *renderData = (RenderData*)inRefCon;
    AudioUnit samplerUnit = renderData->samplerUnit;
    
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
 
        

        OSStatus result = noErr;
        UInt16 beat = 44100 * (60.0f / renderData->tempo);
        UInt16 length = beat * renderData->length;
        UInt32 noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
        UInt32 onVelocity = 127;
        
        
        renderData->frameAccum += inNumberFrames;

        
        if(renderData->isNoteOn){
            

            if(renderData->frameAccumOff > length){
                
                renderData->isNoteOn = false;
                
                // note off (length)
                noteCommand = 	kMIDIMessage_NoteOff << 4 | 0;
                result = MusicDeviceMIDIEvent (samplerUnit, noteCommand, renderData->prevNote, onVelocity,0);
                
                NSLog(@"NOTE OFF %ld",renderData->frameAccum);
            }
            renderData->frameAccumOff += inNumberFrames;
          
        }
        

        if(renderData->frameAccum > beat){
            
            renderData->isNoteOn = true;
            renderData->frameAccum -= beat;
            renderData->frameAccumOff = 0;
            
            float val = 60.0 + (renderData->layer * 12);
            UInt32 noteNum = val;
            
            

            NSLog(@"NOTE ON %ld %ld",renderData->frameAccum, renderData->modCntl);

//            // pitch bend (for fun) use layer
//            result = MusicDeviceMIDIEvent (samplerUnit, 0xE0, 0x00, 0x00, inNumberFrames - renderData->frameAccum);

//            // pan controller
//           result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 10, renderData->modCntl, inNumberFrames - renderData->frameAccum);

            // pitch controller 2
            result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 2, renderData->pitch, inNumberFrames - renderData->frameAccum);

            
            // attack controller 3
            result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 3, renderData->attack * 127.0, inNumberFrames - renderData->frameAccum);

            
//            result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 5, 127.0, inNumberFrames - renderData->frameAccum);

            // mod cotroller (sample start)
            //result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 1, renderData->modCntl, inNumberFrames - renderData->frameAccum);
            
            // oh look, we can do it via sending message directly via kAudioUnitScope_Group
            AudioUnitSetParameter(samplerUnit,
                                  1,
                                  kAudioUnitScope_Group,
                                  0,
                                  renderData->modCntl,
                                  inNumberFrames - renderData->frameAccum);
            
            // note on
            noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
            result = MusicDeviceMIDIEvent (samplerUnit, noteCommand, noteNum, onVelocity, inNumberFrames - renderData->frameAccum);
            renderData->prevNote = noteNum;
            
            
           // renderData->modCntl += 8;
            
            if(renderData->modCntl > 127){
                renderData->modCntl = 0;
            }


        }
        

        
        
        
    }
	return noErr;
	
}
//-------------------------------------------------------------
//
//-------------------------------------------------------------



// private class extension
@interface MainViewController ()
@property (readwrite) Float64   graphSampleRate;
@property (readwrite) AUGraph   processingGraph;
@property (readwrite) AudioUnit samplerUnit;
@property (readwrite) AudioUnit ioUnit;

@property (retain, nonatomic) NSDictionary *samplerPropertyList;
@property (retain, nonatomic) NSArray *wavefiles;

-(NSArray*)getAllBundleFilesForTypes:(NSArray*)types;

- (OSStatus)    injectDataIntoPropertyList:(NSURL*)presetURL withDataBlock:(void (^)(NSDictionary*))blockWithInstrumentData;

-(OSStatus)loadWavefile:(NSString*)path forLayer:(UInt8)index;


- (void)        registerForUIApplicationNotifications;
- (BOOL)        createAUGraph;
- (void)        configureAndStartAudioProcessingGraph: (AUGraph) graph;
- (void)        stopAudioProcessingGraph;
- (void)        restartAudioProcessingGraph;
@end

@implementation MainViewController

@synthesize graphSampleRate     = _graphSampleRate;
@synthesize samplerUnit         = _samplerUnit;
@synthesize ioUnit              = _ioUnit;
@synthesize processingGraph     = _processingGraph;

//@synthesize samplerPropertyList  = _samplerPropertyList;

#pragma mark -
#pragma mark Audio setup


// Set up the audio session for this app.
- (BOOL) setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session. This category supports
    //    audio output with the Ring/Silent switch in the Silent position.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting audio session category."); return NO;}
    
    // Request a desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredHardwareSampleRate: self.graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting preferred hardware sample rate."); return NO;}
    
    // Activate the audio session
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error activating the audio session."); return NO;}
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [mySession currentHardwareSampleRate];
    
    return YES;
}


// Create an audio processing graph.
- (BOOL) createAUGraph {
    
	OSStatus result = noErr;
	AUNode samplerNode, ioNode;

    // Specify the common portion of an audio unit's identify, used for both audio units
    // in the graph.
	AudioComponentDescription cd = {};
	cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
	cd.componentFlags            = 0;
	cd.componentFlagsMask        = 0;

    // Instantiate an audio processing graph
	result = NewAUGraph (&_processingGraph);
    NSCAssert (result == noErr, @"Unable to create an AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
		
	//Specify the Sampler unit, to be used as the first node of the graph
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	
    // Add the Sampler unit node to the graph
	result = AUGraphAddNode (self.processingGraph, &cd, &samplerNode);
    NSCAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);

	// Specify the Output unit, to be used as the second and final node of the graph	
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;  

    // Add the Output unit node to the graph
	result = AUGraphAddNode (self.processingGraph, &cd, &ioNode);
    NSCAssert (result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);

    
    // Open the graph
	result = AUGraphOpen (self.processingGraph);
    NSCAssert (result == noErr, @"Unable to open the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Connect the Sampler unit to the output unit
	result = AUGraphConnectNodeInput (self.processingGraph, samplerNode, 0, ioNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);

	// Obtain a reference to the Sampler unit from its node
	result = AUGraphNodeInfo (self.processingGraph, samplerNode, 0, &_samplerUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int) result, (const char *)&result);

    renderData = (RenderData*)malloc(sizeof(RenderData));
    renderData->tempo = 160.0f;
    renderData->frameAccum = 0;
    renderData->frameAccumOff = 0;
    renderData->samplerUnit = _samplerUnit;
    AudioUnitAddRenderNotify(_samplerUnit, renderCallback, renderData);
    renderData->modCntl = 0;
    renderData->prevNote = 0;
    renderData->pitch = 64;
    renderData->layer = 0;
    renderData->length = 1.0f;
    renderData->attack = 0.0f;
    renderData->isNoteOn = false;
    
	// Obtain a reference to the I/O unit from its node
	result = AUGraphNodeInfo (self.processingGraph, ioNode, 0, &_ioUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    return YES;
}


// Starting with instantiated audio processing graph, configure its 
// audio units, initialize it, and start it.
- (void) configureAndStartAudioProcessingGraph: (AUGraph) graph {

    OSStatus result = noErr;
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof (framesPerSlice);
    UInt32 sampleRatePropertySize = sizeof (self.graphSampleRate);
    
    result = AudioUnitInitialize (self.ioUnit);
    NSCAssert (result == noErr, @"Unable to initialize the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Set the I/O unit's output sample rate.
    result =    AudioUnitSetProperty (
                  self.ioUnit,
                  kAudioUnitProperty_SampleRate,
                  kAudioUnitScope_Output,
                  0,
                  &_graphSampleRate,
                  sampleRatePropertySize
                );
    
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Obtain the value of the maximum-frames-per-slice from the I/O unit.
    result =    AudioUnitGetProperty (
                    self.ioUnit,
                    kAudioUnitProperty_MaximumFramesPerSlice,
                    kAudioUnitScope_Global,
                    0,
                    &framesPerSlice,
                    &framesPerSlicePropertySize
                );

    NSCAssert (result == noErr, @"Unable to retrieve the maximum frames per slice property from the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Set the Sampler unit's output sample rate.
    result =    AudioUnitSetProperty (
                  self.samplerUnit,
                  kAudioUnitProperty_SampleRate,
                  kAudioUnitScope_Output,
                  0,
                  &_graphSampleRate,
                  sampleRatePropertySize
                );
    
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Set the Sampler unit's maximum frames-per-slice.
    result =    AudioUnitSetProperty (
                    self.samplerUnit,
                    kAudioUnitProperty_MaximumFramesPerSlice,
                    kAudioUnitScope_Global,
                    0,
                    &framesPerSlice,
                    framesPerSlicePropertySize
                );
    
    NSAssert( result == noErr, @"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    if (graph) {
        
        // Initialize the audio processing graph.
        result = AUGraphInitialize (graph);
        NSAssert (result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Start the graph
        result = AUGraphStart (graph);
        NSAssert (result == noErr, @"Unable to start audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Print out the graph to the console
        CAShow (graph); 
    }
}


- (IBAction)onReleaseChanged:(UISlider *)sender {
    
    
    UISlider *slider = (UISlider*)sender;
    renderData->tempo = 60.0f + ([slider value] * 200.0);
    self.tempoLabel.text = [NSString stringWithFormat:@"%.0f",renderData->tempo];
}

- (IBAction)onLengthChanged:(UISlider *)sender {
    
    renderData->length = [sender value];
}

- (IBAction)onPitchChanged:(UISlider *)sender {
    
    
    UInt8 pitch = (64 - 12) + (24 * [sender value]);
    
    renderData->pitch = pitch;
    
}

- (IBAction)onPlaySequence:(id)sender {
    
    UIButton *btn = (UIButton*)sender;
    btn.selected = !btn.selected;

    
    [btn setTitle:@"Play Sequence" forState:UIControlStateNormal];
    [btn setTitle:@"Stop Sequence" forState:UIControlStateSelected];
    
    
    if(btn.selected){
        
    }else{
        
    }
}

- (IBAction)onLayerSelection:(UISegmentedControl *)sender {

    renderData->layer = [sender selectedSegmentIndex];

}

- (IBAction)onAttackChanged:(UISlider *)sender {
    
    renderData->attack = [sender value];
}


// Load the Trombone preset




-(NSArray*)getAllBundleFilesForTypes:(NSArray*)types{

    NSError *err = nil;

    NSMutableArray *collect = [[NSMutableArray alloc] init] ;
    NSArray *rc = [[NSFileManager defaultManager]
                   contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:&err];
    
    if(err){
        NSLog(@"%@ : %@ : %@",
             [err localizedFailureReason],
             [err localizedDescription],
             [err localizedRecoverySuggestion]);
    }
    
    // get all files with correct extensions
    for(NSString *title in [rc pathsMatchingExtensions:types]){
        [collect addObject:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:title]];
    }
    
    return collect;
    
}
-(void)loadPropertyList:(NSURL*)presetURL{

    [self injectDataIntoPropertyList:presetURL
                       withDataBlock:^(NSDictionary* plData){
                           self.samplerPropertyList = plData;
                       }];
}



-(OSStatus)loadWavefile:(NSString*)path forLayer:(UInt8)index{

    // checks to see if waveFile is already in the propList as a file-reference
    // if it is, get it's id and set for layer
    // else insert as a file-reference and set for layer

    OSStatus result = noErr;
    
    NSMutableDictionary *files = [self.samplerPropertyList objectForKey:@"file-references"];
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    [[files allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        [titles addObject:[obj lastPathComponent]];
    }];
    

    __block BOOL makeNew = YES;
    
    [titles enumerateObjectsUsingBlock:^(id title, NSUInteger idx, BOOL *stop){

        if([title isEqualToString:[path lastPathComponent]]){

            // file ref exists
            stop = YES;
            makeNew = NO;
            
            // look for title in the file-ref list
            [[files allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *fileStop){

                if([[obj lastPathComponent] isEqualToString:title]){
                    
                    // found possible keys
                    NSArray *keys = [files allKeysForObject:obj];

                    // assume first key is the one
                    NSString *key = [keys firstObject];
                    
                    // strip "Sample:"
                    NSString *value = [[key componentsSeparatedByString:@":"] lastObject] ;
                    NSNumber *num = [NSNumber numberWithInt:[value intValue]];
                    
                    //set zone wavefile reference id
                    [self setWavefileID:num forLayer:index];
                }
            
            }];
            
        }else{
        }
    
    }];
    
    if(makeNew){
        // file ref doesn't exist
        
        
        // generate an ID
        
        //••• need to generate UNIQUE id
        NSNumber *wavefileID = @(rand() % 100);
        
        NSMutableDictionary *files = [self.samplerPropertyList objectForKey:@"file-references"];
        
        NSString *key = [NSString stringWithFormat:@"Sample:%@",wavefileID];
        
        // and finally set it
        [files setValue:path forKey:key];
        
        //set zone wavefile reference id
        [self setWavefileID:wavefileID forLayer:index];

    }
    
    NSLog(@"%@",files);
//    NSLog(@"%@",titles);
//    NSLog(@"%@",path);
   
    return result;
}

-(void)setWavefileID:(NSNumber*)wavefileID forLayer:(UInt8)index{
    
    OSStatus result = noErr;

    NSDictionary *instrument = [self.samplerPropertyList objectForKey:@"Instrument"];
    
    // get the layer at index
    NSArray *layers = [instrument objectForKey:@"Layers"];
    NSDictionary *layer = [layers objectAtIndex:index];
    
    
    // each zone has an index to a waveform in the file-references dictinaory
    NSArray *zones = [layer objectForKey:@"Zones"];
    NSDictionary *zone = [zones objectAtIndex:0];
    [zone setValue:wavefileID forKey:@"waveform"];
    
    NSLog(@"%@",zone);
    
    CFPropertyListRef presetPropertyList = (__bridge CFPropertyListRef)self.samplerPropertyList;
    
    result = AudioUnitSetProperty(
                                  self.samplerUnit,
                                  kAudioUnitProperty_ClassInfo,
                                  kAudioUnitScope_Global,
                                  0,
                                  &presetPropertyList,
                                  sizeof(CFPropertyListRef)
                                  );


}

//-(OSStatus)changeWavefile:(NSString*)path forLayer:(UInt8)index{
//
//    OSStatus result = noErr;
//
//    NSDictionary *instrument = [self.samplerPropertyList objectForKey:@"Instrument"];
//    
//    // get the layer at index
//    NSArray *layers = [instrument objectForKey:@"Layers"];
//    NSDictionary *layer = [layers objectAtIndex:index];
//    
//    NSNumber *num = @(100 + index);
//    
//    // each zone has an index to a waveform in the file-references dictinaory
//    NSArray *zones = [layer objectForKey:@"Zones"];
//    NSDictionary *zone = [zones objectAtIndex:0];
//    [zone setValue:num forKey:@"waveform"];
//    
//    // add the file-reference path
//    NSMutableDictionary *files = [self.samplerPropertyList objectForKey:@"file-references"];
//    
//    NSString *key = [NSString stringWithFormat:@"Sample:%@",num];
//    
//    // and finally set it
//    [files setValue:path forKey:key];
//    
////    NSLog(@"%@",self.samplerPropertyList);
//    
//    CFPropertyListRef presetPropertyList = (__bridge CFPropertyListRef)self.samplerPropertyList;
//
//    result = AudioUnitSetProperty(
//                                  self.samplerUnit,
//                                  kAudioUnitProperty_ClassInfo,
//                                  kAudioUnitScope_Global,
//                                  0,
//                                  &presetPropertyList,
//                                  sizeof(CFPropertyListRef)
//                                  );
//    
//
//    NSLog(@"%@",zone);
//    NSLog(@"%@",files);
//    
//    return result;
//    
//}

-(OSStatus)injectDataIntoPropertyList:(NSURL*)presetURL withDataBlock:(void (^)(NSDictionary*))blockWithInstrumentData{

    CFDataRef propertyResourceData = 0;
	Boolean status;
	SInt32 errorCode = 0;
    OSStatus result = noErr;

	// Read from the URL and convert into a CFData chunk
	status = CFURLCreateDataAndPropertiesFromResource (
                                                       kCFAllocatorDefault,
                                                       (__bridge CFURLRef) presetURL,
                                                       &propertyResourceData,
                                                       NULL,
                                                       NULL,
                                                       &errorCode
                                                       );
    
    NSAssert (status == YES && propertyResourceData != 0,
              @"Unable to create data and properties from a preset. Error code: %d '%.4s'",
              (int) errorCode,
              (const char *)&errorCode);
   	
	// Convert the data object into a property list
	CFPropertyListRef presetPropertyList = 0;
	CFPropertyListFormat dataFormat = 0;
	CFErrorRef errorRef = 0;
	presetPropertyList = CFPropertyListCreateWithData (
                                                       kCFAllocatorDefault,
                                                       propertyResourceData,
                                                       kCFPropertyListImmutable,
                                                       &dataFormat,
                                                       &errorRef
                                                       );
    
	if (presetPropertyList != 0) {
        
        NSDictionary *plData = (__bridge NSDictionary*)presetPropertyList;

        blockWithInstrumentData(plData);
        
        presetPropertyList = (__bridge CFPropertyListRef)plData;
        
		result = AudioUnitSetProperty(
                                      self.samplerUnit,
                                      kAudioUnitProperty_ClassInfo,
                                      kAudioUnitScope_Global,
                                      0,
                                      &presetPropertyList,
                                      sizeof(CFPropertyListRef)
                                      );
        

        CFRelease(presetPropertyList);

    }
    
    
    if (errorRef) CFRelease(errorRef);
	CFRelease (propertyResourceData);

    return result;
}

#pragma mark -
#pragma mark Audio control
// Stop the audio processing graph
- (void) stopAudioProcessingGraph {

    OSStatus result = noErr;
	if (self.processingGraph) result = AUGraphStop(self.processingGraph);
    NSAssert (result == noErr, @"Unable to stop the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

// Restart the audio processing graph
- (void) restartAudioProcessingGraph {

    OSStatus result = noErr;
	if (self.processingGraph) result = AUGraphStart (self.processingGraph);
    NSAssert (result == noErr, @"Unable to restart the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}


#pragma mark -
#pragma mark Audio session delegate methods

// Respond to an audio interruption, such as a phone call or a Clock alarm.
- (void) beginInterruption {
    

    // Interruptions do not put an AUGraph object into a "stopped" state, so
    //    do that here.
    [self stopAudioProcessingGraph];
}


// Respond to the ending of an audio interruption.
- (void) endInterruptionWithFlags: (NSUInteger) flags {
    
    NSError *endInterruptionError = nil;
    [[AVAudioSession sharedInstance] setActive: YES
                                         error: &endInterruptionError];
    if (endInterruptionError != nil) {
        
        NSLog (@"Unable to reactivate the audio session.");
        return;
    }
    
    if (flags & AVAudioSessionInterruptionFlags_ShouldResume) {
        
        /*
         In a shipping application, check here to see if the hardware sample rate changed from 
         its previous value by comparing it to graphSampleRate. If it did change, reconfigure 
         the ioInputStreamFormat struct to use the new sample rate, and set the new stream 
         format on the two audio units. (On the mixer, you just need to change the sample rate).
         
         Then call AUGraphUpdate on the graph before starting it.
         */
        
        [self restartAudioProcessingGraph];
    }
}


#pragma mark - Application state management

// The audio processing graph should not run when the screen is locked or when the app has 
//  transitioned to the background, because there can be no user interaction in those states.
//  (Leaving the graph running with the screen locked wastes a significant amount of energy.)
//
// Responding to these UIApplication notifications allows this class to stop and restart the 
//    graph as appropriate.
- (void) registerForUIApplicationNotifications {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleResigningActive:)
                               name: UIApplicationWillResignActiveNotification
                             object: [UIApplication sharedApplication]];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleBecomingActive:)
                               name: UIApplicationDidBecomeActiveNotification
                             object: [UIApplication sharedApplication]];
}


- (void) handleResigningActive: (id) notification {
    
    [self stopAudioProcessingGraph];
}


- (void) handleBecomingActive: (id) notification {
    
    [self restartAudioProcessingGraph];
}

- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
        
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
        
    // If object initialization fails, return immediately.
    if (!self) {
        _samplerPropertyList = [[NSDictionary alloc] init];
        
        return nil;
    }
    
    

    // Set up the audio session for this app, in the process obtaining the 
    // hardware sample rate for use in the audio processing graph.
    BOOL audioSessionActivated = [self setupAudioSession];
    NSAssert (audioSessionActivated == YES, @"Unable to set up audio session.");
    
    // Create the audio processing graph; place references to the graph and to the Sampler unit
    // into the processingGraph and samplerUnit instance variables.
    [self createAUGraph];
    [self configureAndStartAudioProcessingGraph: self.processingGraph];
    
    return self;
}

- (void) viewDidLoad {

    [super viewDidLoad];
    
    NSString *title = @"SweepPad9";
	NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:title ofType:@"aupreset"]];

    self.wavefiles = [self getAllBundleFilesForTypes:@[@"wav",@"aiff",@"mp3"]];
    
    [self loadPropertyList:presetURL];
    [self registerForUIApplicationNotifications];


    // only after property list has loaded
    // load first wavefile in tableview
    NSString *path = [self.wavefiles objectAtIndex:0];
    [self loadWavefile:path forLayer:[self.layerSelection selectedSegmentIndex]];
    
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self.filesTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    
    [self.tempoSlider setValue:0.5];
}




- (void) viewDidUnload {
    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) didReceiveMemoryWarning {

    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
#pragma mark - Tableview DataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.wavefiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    NSString *title = [[[self.wavefiles objectAtIndex:indexPath.row] lastPathComponent] stringByDeletingPathExtension];
    
    cell.textLabel.text = title;
    cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *path = [self.wavefiles objectAtIndex:indexPath.row];
    [self loadWavefile:path forLayer:[self.layerSelection selectedSegmentIndex]];

}
@end
