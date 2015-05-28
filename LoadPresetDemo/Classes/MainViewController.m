/*
     File: MainViewController.m

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
static void noteOn(RenderData     *renderData,
                     UInt32			inNumberFrames);

static void noteOFF(RenderData     *renderData,
                   UInt32			inNumberFrames);

static OSStatus renderCallback(	void *							inRefCon,
							   AudioUnitRenderActionFlags *	ioActionFlags,
							   const AudioTimeStamp *			inTimeStamp,
							   UInt32							inBusNumber,
							   UInt32							inNumberFrames,
							   AudioBufferList *				ioData){
	
    RenderData *renderData = (RenderData*)inRefCon;
    
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {

        UInt16 beat = 44100 * (60.0f / renderData->tempo);
        UInt16 length = beat * renderData->length;
        
        if(renderData->frameAccumOff > length){
            renderData->frameAccumOff = -(beat - length);
            noteOFF(renderData, -beat);
        }
        
        if(renderData->frameAccum > beat){
            renderData->frameAccum = 0;
            noteOn(renderData,-beat);
        }
        
        renderData->frameAccum += inNumberFrames;
        renderData->frameAccumOff += inNumberFrames;
    }
    

	return noErr;
	
}


static void noteOn(RenderData     *renderData,
                     UInt32			inNumberFrames){
    
    OSStatus result = noErr;

    AudioUnit samplerUnit = renderData->samplerUnit;
    UInt32 noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
    UInt32 onVelocity = 127;
    float val = 12.0 + (renderData->layer * 12);
    UInt32 noteNum = val;
    
    //            // pitch bend (for fun) use layer
    //            result = MusicDeviceMIDIEvent (samplerUnit, 0xE0, 0x00, 0x00, inNumberFrames - renderData->frameAccum);
    
    //            // pan controller
    //           result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 10, renderData->modCntl, inNumberFrames - renderData->frameAccum);
    
    // pitch controller 2
    // bipolar -6400 to 6400
    //UInt8 pitch = 52 + renderData->modCntl;
    UInt8 pitch = (64 - 13) + (24 * renderData->pitch);
    
    
    //UInt8 pitch = (64 - 12) + (2 * (rand()%(int)(1+48*renderData->pitch)));
    //UInt8 pitch = 64 + (2 * (rand()%(int)(1+6*renderData->pitch)));
    result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 2, pitch, inNumberFrames - renderData->frameAccum);
    
    // hold controller 3
    
    //• need to work tempo into this formulars
//    result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 3, renderData->length * 127.0, inNumberFrames - renderData->frameAccum);

    // attack controller 4
    //result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 4, renderData->attack * 127.0, inNumberFrames - renderData->frameAccum);

    // decay controller 5
    //result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 5, renderData->release * 127.0, inNumberFrames - renderData->frameAccum);

    
//    hold = length - decay
    
    
    // attack controller 3
//-    result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 3, renderData->attack * 127.0, inNumberFrames - renderData->frameAccum);
    
    



    // decay controller 8
//    result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 8, renderData->release * 127.0, inNumberFrames - renderData->frameAccum);

    
    
    
    
    // sample start
    // Sampler Start factor 0 to 0.99
    UInt32 pos = renderData->position * 130.0f; // what the hey ? it seems we need to over scale
    result = MusicDeviceMIDIEvent (samplerUnit, 0xB0, 1, pos, inNumberFrames - renderData->frameAccum);
    
    // oh look, we can do it via sending message directly via kAudioUnitScope_Group
    //            AudioUnitSetParameter(samplerUnit,
    //                                  1,
    //                                  kAudioUnitScope_Group,
    //                                  0,
    //                                  pos,
    //                                  inNumberFrames - renderData->frameAccum);
    
    
    // note on
    noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
    result = MusicDeviceMIDIEvent (samplerUnit, noteCommand, noteNum, onVelocity, inNumberFrames - renderData->frameAccum);
    renderData->prevNote = noteNum;
    
    
    // test for moving thru a sample
    renderData->modCntl += 2;
    
    if(renderData->modCntl > 24){
        renderData->modCntl = 0;
    }
    
    NSLog(@"NOTE ON");

}

static void noteOFF(RenderData     *renderData,
                    UInt32			inNumberFrames){

    OSStatus result = noErr;
    
    AudioUnit samplerUnit = renderData->samplerUnit;
    UInt32 noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
    UInt32 onVelocity = 0;

    // note off (length)
    noteCommand = 	kMIDIMessage_NoteOff << 4 | 0;
    result = MusicDeviceMIDIEvent (samplerUnit, noteCommand, renderData->prevNote, onVelocity,0);
    
    NSLog(@"NOTE OFF");

    //NSLog(@"NOTE OFF %ld",renderData->frameAccumOff);

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

//@property (retain, nonatomic) NSDictionary *samplerPropertyList;
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
    renderData->layer = 0;
    
    renderData->pitch = 0.5f;
    renderData->length = 1.0f;
    renderData->attack = 0.1f;
    renderData->release = 1.0f;
    renderData->position = 0.0f;
    
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

//    // Set the Sampler unit's output sample rate.
//    result =    AudioUnitSetProperty (
//                  self.samplerUnit,
//                  kAudioUnitProperty_SampleRate,
//                  kAudioUnitScope_Output,
//                  0,
//                  &_graphSampleRate,
//                  sampleRatePropertySize
//                );
//    
//    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);

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


- (IBAction)onTempoChanged:(UISlider *)sender {
    
    
    UISlider *slider = (UISlider*)sender;
    renderData->tempo = 60.0f + ([slider value] * 400.0);
    self.tempoLabel.text = [NSString stringWithFormat:@"%.0f",renderData->tempo];
    
    // need to reset these since large jumps in tempo will set the accum's out of sync
    renderData->frameAccumOff = 0;
    renderData->frameAccum = 0;
}

- (IBAction)onLengthChanged:(UISlider *)sender {
    
    renderData->length = [sender value];
}

- (IBAction)onPitchChanged:(UISlider *)sender {
    
    
    
    renderData->pitch = [sender value];
    
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

- (IBAction)onReleaseChanged:(UISlider *)sender {
    renderData->release = [sender value];
}

- (IBAction)onPositionChanged:(UISlider *)sender {
    
    float val = roundf([sender value] * 16.0f) / 16.0;
    [sender setValue:val];
    NSLog(@"%f",[sender value]);
    
    renderData->position = [sender value];
}


// Load the Trombone preset




-(NSArray*)getAllBundleFilesForTypes:(NSArray*)types{

    NSError *err = nil;

    NSMutableArray *collect = [[NSMutableArray alloc] init] ;
    NSArray *rc = [[NSFileManager defaultManager]
                   contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:&err];
    
    //subpathsOfDirectoryAtPath
    
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

#pragma mark -
#pragma mark Sampler Properties

-(OSStatus)loadPropertyList:(NSURL*)presetURL{
    
    OSStatus result = noErr;
    
    // Read from the URL and convert into a CFData chunk
    NSError * outError = nil;
    const NSDataReadingOptions DataReadingOptions = 0;
    
    NSData * data = [NSData dataWithContentsOfURL:presetURL
                                          options:DataReadingOptions
                                            error:&outError];
    
    if (outError != nil) {NSLog (@"Error dataWithContentsOfURL."); return NO;}
    
    
    // Convert the data object into a property list
    CFPropertyListRef presetPropertyList = 0;
    CFPropertyListFormat dataFormat = 0;
    CFErrorRef errorRef = 0;
    presetPropertyList = CFPropertyListCreateWithData (
                                                       kCFAllocatorDefault,
                                                       (__bridge CFDataRef)data,
                                                       kCFPropertyListImmutable,
                                                       &dataFormat,
                                                       &errorRef
                                                       );
    
    if (errorRef != nil) {NSLog (@"Error CFPropertyListCreateWithData."); return NO;}
    
    if (presetPropertyList != 0) {
        result = AudioUnitSetProperty(
                                      self.samplerUnit,
                                      kAudioUnitProperty_ClassInfo,
                                      kAudioUnitScope_Global,
                                      0,
                                      &presetPropertyList,
                                      sizeof(CFPropertyListRef)
                                      );
        
        if (result != noErr) {NSLog (@"Error AudioUnitSetProperty : kAudioUnitProperty_ClassInfo %d",result); return NO;}
        
        CFRelease(presetPropertyList);
        
    }else{
        NSLog(@"Error No presetPropertyList");
    }
    
    if (errorRef) CFRelease(errorRef);

    return result;
}




-(void)duplicateLayers:(NSUInteger)numberOfLayers{

    [self commitToSamplerWithDataBlock:^(NSDictionary *data) {

        // add those duplicate layers
        NSMutableArray *layers = data[@"Instrument"][@"Layers"];

        for(int i=1;i<numberOfLayers;i++){

            NSDictionary *oldLayer = [layers objectAtIndex:0];

            // make a deep copy of entire layer dict.
            NSMutableDictionary *newLayer = (__bridge NSMutableDictionary *)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)oldLayer, kCFPropertyListMutableContainers);

            NSString *key = @"ID";
            NSNumber *val = @([[oldLayer objectForKey:key] intValue] + i);
            [newLayer setValue:val forKey:key];

            // insert the layer copy to structure
            [layers insertObject:newLayer atIndex:i];
        
        }
        
        // now add valid data/connections
        NSDictionary *oldLayer = [layers objectAtIndex:0];
        
        for(int i=1;i<numberOfLayers;i++){
            
            NSDictionary *newLayer = [layers objectAtIndex:i];
            
            NSString *key = @"key offset";
            NSNumber *val = @([oldLayer[key] intValue] - (12 * i));
            [newLayer setValue:val forKey:key];
            
            key = @"max key";
            val = @([oldLayer[key] intValue] + (12 * i));
            [newLayer setValue:val forKey:key];
            
            key = @"min key";
            val = @([oldLayer[key] intValue] + (12 * i));
            [newLayer setValue:val forKey:key];
            
            
            // Connections are completely undocumented therefore this code will need to be continually maintained.
            // Apple may change how any of this behaves.
            NSArray *connections = [oldLayer objectForKey:@"Connections"];
            
            [connections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                NSNumber *origDestination = obj[@"destination"];
                NSNumber *newDestination = @([origDestination intValue] + (256*i));
                NSNumber *origSource = obj[@"source"];
                NSNumber *newSource = @([origSource intValue] + (256*i));
                
                // for envelope (1343225856) we need to
                if([origDestination isEqualToNumber:@(1343225856)]){
                    
                    [[newLayer[@"Connections"] objectAtIndex:idx] setValue:newDestination forKey:@"destination"];
                    [[newLayer[@"Connections"] objectAtIndex:idx] setValue:newSource forKey:@"source"];
                    
                    newDestination = [[newLayer[@"Connections"] objectAtIndex:idx] objectForKey:@"destination"];
                    newSource = [[newLayer[@"Connections"] objectAtIndex:idx] objectForKey:@"source"];
                    NSLog(@"Layer %@ %@ : %@ | %@ : %@",newLayer[@"ID"],origDestination,newDestination,origSource,newSource);
                    
                }else{
                    
                    [[newLayer[@"Connections"] objectAtIndex:idx] setValue:newDestination forKey:@"destination"];
                    newDestination = [[newLayer[@"Connections"] objectAtIndex:idx] objectForKey:@"destination"];
                    NSLog(@"Layer %@ %@ : %@",newLayer[@"ID"],origDestination,newDestination);
                }
                
            }];
        }
        
    }];
}

-(OSStatus)populateSamplerWithAudioFilePaths:(NSArray*)audioFilePaths{

    // checks to see if waveFile is already in the propList as a file-reference
    // if it is, get it's id and set for layer
    // else insert as a file-reference and set for layer
    OSStatus result = noErr;
    
    [audioFilePaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
    
        NSString *path = (NSString*)obj;
        
        [self commitToSamplerWithDataBlock:^(NSDictionary *data) {
            
            NSDictionary *files = data[@"file-references"];
            NSMutableArray *titles = [[NSMutableArray alloc] init];
            [[files allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
                [titles addObject:[obj lastPathComponent]];
            }];
            
            [titles enumerateObjectsUsingBlock:^(id title, NSUInteger idx, BOOL *stop){
                
                if([title isEqualToString:[path lastPathComponent]]){
                    
                    // file ref exists, so let's stop enumerating
                    stop = YES;
                    
                    NSLog(@"File %@ already exists",title);
                    
                }else{
                    // need to generate UNIQUE id
                    NSNumber *wavefileID = [NSNumber numberWithLong:(arc4random() % (UInt32)(INT32_MAX - 1))];
                    
                    // collect all id's
                    NSMutableArray *allIDS = [[NSMutableArray alloc] init];
                    [[files allKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *fileStop){
                        NSString *value = [[obj componentsSeparatedByString:@":"] lastObject] ;
                        [allIDS addObject:[NSNumber numberWithInteger:[value integerValue]]];
                    }];
                    
                    // hang here till we wave a unique new id
                    while([allIDS containsObject:wavefileID]){
                        wavefileID = [NSNumber numberWithLong:(arc4random() % (UInt32)(INT32_MAX - 1))];
                    }
                    
                    // and finally set it
                    NSMutableDictionary *files = data[@"file-references"];
                    NSString *key = [NSString stringWithFormat:@"Sample:%@",wavefileID];
                    
                    // add to files reference dict.
                    [files setValue:path forKey:key];
                    
                }
            }];
            
        }];
    }];

    return result;

    
}
-(OSStatus)loadWavefile:(NSString*)path forLayer:(UInt8)index{

    // checks to see if waveFile is already in the propList as a file-reference
    // if it is, get it's id and set for layer
    // else insert as a file-reference and set for layer

    OSStatus result = noErr;
    
    [self commitToSamplerWithDataBlock:^(NSDictionary *data) {
        
        NSMutableDictionary *files = data[@"file-references"];
        NSMutableArray *titles = [[NSMutableArray alloc] init];
        [[files allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            [titles addObject:[obj lastPathComponent]];
        }];
        
        [titles enumerateObjectsUsingBlock:^(id title, NSUInteger idx, BOOL *stop){
            
            if([title isEqualToString:[path lastPathComponent]]){
                
                // file ref exists, so let's stop enumerating
                stop = YES;
                
                // look for title in the file-ref list
                [[files allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *fileStop){
                    
                    if([[obj lastPathComponent] isEqualToString:title]){
                        
                        // found possible keys
                        NSArray *keys = [files allKeysForObject:obj];
                        
                        // assume first key is the one
                        NSString *key = [keys firstObject];
                        
                        // strip "Sample:"
                        NSString *value = [[key componentsSeparatedByString:@":"] lastObject] ;
                        NSNumber *wavefileID = [NSNumber numberWithInt:[value intValue]];
                        
                        // calculate length of a beat
                        float length = (60.0/renderData->tempo);
                        
                        // set envelopes hold as beat length
                        NSMutableDictionary *layer = data[@"Instrument"][@"Layers"][index];
                        NSMutableDictionary *envelope = layer[@"Envelopes"][0];
                        NSMutableDictionary *holdStage = envelope[@"Stages"][2];
                        [holdStage setValue:@(length) forKey:@"time"];

                        
                        NSLog(@"Loading %@ into Sampler : Tempo %f",title,60.0/renderData->tempo);
                        
                        [self setWavefileID:wavefileID forLayer:data[@"Instrument"][@"Layers"][index]];

                    }
                    
                }];
                
            }
        }];
    }];
    
    return result;
    
}

-(void)setWavefileID:(NSNumber*)wavefileID forLayer:(NSMutableDictionary*)layer{

    // each zone has an index to a waveform in the file-references dictinaory
    NSMutableArray *zones = layer[@"Zones"];
    NSMutableDictionary *zone = zones[0];
    [zone setValue:wavefileID forKey:@"waveform"];
    
}

-(OSStatus)commitToSamplerWithDataBlock:(void (^)(NSDictionary *data))blockWithInstrumentData{

    // get data from sampler
    OSStatus result = noErr;
    CFPropertyListRef presetPropertyList = 0;
    UInt32 propListSize =sizeof(CFPropertyListRef);
    
    result = AudioUnitGetProperty(
                                  self.samplerUnit,
                                  kAudioUnitProperty_ClassInfo,
                                  kAudioUnitScope_Global,
                                  0,
                                  &presetPropertyList,
                                  &propListSize
                                  );
    
    if (result != noErr) {NSLog (@"Error CFPropertyListGetData %d",result); return NO;}

    // pass objc data to block
    NSDictionary *plData = (__bridge NSDictionary*)presetPropertyList;

    blockWithInstrumentData(plData);

    // convert back and pass to sampler
    presetPropertyList = (__bridge CFPropertyListRef)plData;
    
    result = AudioUnitSetProperty(
                                  self.samplerUnit,
                                  kAudioUnitProperty_ClassInfo,
                                  kAudioUnitScope_Global,
                                  0,
                                  &presetPropertyList,
                                  sizeof(CFPropertyListRef)
                                  );
    
    if (result != noErr) {NSLog (@"Error AudioUnitSetProperty : kAudioUnitProperty_ClassInfo %d",result); return NO;}

    
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
//        _samplerPropertyList = [[NSDictionary alloc] init];
        
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

    
    NSString *title = @"SamplerPreset25"; // pitch, start factor
//    NSString *title = @"SamplerPreset28"; // hold
//    NSString *title = @"SamplerPreset29"; // hold, attack
//    NSString *title = @"SamplerPreset30"; // hold, attack, decay
    
    
//    NSString *title = @"SweepPad18-64";
	NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:title ofType:@"aupreset"]];

    self.wavefiles = [self getAllBundleFilesForTypes:@[@"wav",@"aiff",@"mp3",@"m4a",@"aac"]];
    
    [self loadPropertyList:presetURL];
    
    [self duplicateLayers:8];
    
    [self populateSamplerWithAudioFilePaths:self.wavefiles];

    
    
    
    [self registerForUIApplicationNotifications];

    
    [self.layerSelection setSelectedSegmentIndex:0];
    // only after property list has loaded
    // load first wavefile in tableview
//    NSString *path = [self.wavefiles objectAtIndex:0];
//    [self loadWavefile:path forLayer:[self.layerSelection selectedSegmentIndex]];

    [self.tempoSlider setValue:0.5];

}




-(void)viewDidAppear:(BOOL)animated{
    
    
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
