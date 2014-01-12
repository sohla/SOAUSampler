/*
     File: MainViewController.h
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

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>


typedef struct RenderDeataStruct RenderData;

struct RenderDeataStruct {
    
    float       tempo;
	UInt32      frameAccum;
    AudioUnit   samplerUnit;
    UInt32      modCntl;
    UInt32      prevNote;
    UInt32      pitch;
    UInt8       layer;

};




@interface MainViewController : UIViewController <AVAudioSessionDelegate>{
    RenderData *renderData;
}

@property (nonatomic, strong) IBOutlet UIButton *presetOneButton;
@property (nonatomic, strong) IBOutlet UIButton *presetTwoButton;
@property (nonatomic, strong) IBOutlet UIButton *lowNoteButton;
@property (nonatomic, strong) IBOutlet UIButton *midNoteButton;
@property (nonatomic, strong) IBOutlet UIButton *highNoteButton;
@property (nonatomic, strong) IBOutlet UILabel  *currentPresetLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *layerSelection;

- (IBAction) loadPresetOne:(id)sender;
- (IBAction) loadPresetTwo:(id)sender;
- (IBAction) startPlayLowNote:(id)sender;
- (IBAction) stopPlayLowNote:(id)sender;
- (IBAction) startPlayMidNote:(id)sender;
- (IBAction) stopPlayMidNote:(id)sender;
- (IBAction) startPlayHighNote:(id)sender;
- (IBAction) stopPlayHighNote:(id)sender;
- (IBAction) onReleaseChanged:(UISlider *)sender;
- (IBAction) onPlaySequence:(id)sender;
- (IBAction) onLayerSelection:(UISegmentedControl *)sender;


//-(void)changePitchTo:(int)val;
/*
 
 grep -r '-10851' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk/System/Library/Frameworks/AudioUnit.framework
 
 
 grep -r '-10851' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk/System/Library/Frameworks/AudioToolbox.framework
 
 
 grep  '-10851' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk/System/Library/Frameworks/AVFoundation.framework
 
 
 */


/*
 tested so far :
    note on
    note off
    pitch bend (do we need it?)
    pan control (midi cntl #10)
    pitch control (midi cntl #2) 
    sampler start (midi cntl #1) mapped to sample start factor
 
 
 
 
 test for layers / swapping layers
    can we share connections? test this : yes this works
    how and what to test with ui
 
 need to reload data : ie propslist from sampler to populate
    store as a NSDictionary
 
    loadFromPropListFile:(URL)...
 
    when we want to chamge anything
 
    get propList from sampler to re-populate the dict (sync)
    
 
 Separate file-reference from linking to zone
 
    loadWaveFile forLayer
 
        get wavefile-reference list
 
        does it exist ? get id : generate id & add to list
 
 AudioFile list
 
    simple tableview of some type
 
 
 
Note Off :
    test for logic : need to remember last note and turn it off
 
 
 
 
 
 Model : Track
    Sampler
        wavefile list
 
 
 
 
 
 
 
 
 
 test for : attack / decay
 
 start to think
    what the relationship of the envelope
    previous model of what the attack/decay is
    envelope <-> length/time
 
 
 
 
 
 */

@end
