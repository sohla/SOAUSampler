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
	SInt32      frameAccum;
	SInt32      frameAccumOff;
    AudioUnit   samplerUnit;
    UInt32      modCntl;
    UInt32      prevNote;
    UInt32      pitch;
    UInt8       layer;
    Boolean     isNoteOn;
    
    float length;
    float attack;
};




@interface MainViewController : UIViewController <AVAudioSessionDelegate, UITableViewDelegate, UITableViewDataSource>{
    RenderData *renderData;
}

@property (weak, nonatomic) IBOutlet UISegmentedControl *layerSelection;
@property (weak, nonatomic) IBOutlet UILabel *tempoLabel;
@property (weak, nonatomic) IBOutlet UISlider *tempoSlider;

@property (weak, nonatomic) IBOutlet UITableView *filesTableView;
- (IBAction) onReleaseChanged:(UISlider *)sender;
- (IBAction)onLengthChanged:(UISlider *)sender;
- (IBAction)onPitchChanged:(UISlider *)sender;
- (IBAction) onLayerSelection:(UISegmentedControl *)sender;

- (IBAction)onAttackChanged:(UISlider *)sender;

//-(void)changePitchTo:(int)val;
/*
 
 grep -r '-10851' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk/System/Library/Frameworks/AudioUnit.framework
 
 
 grep -r '-10851' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk/System/Library/Frameworks/AudioToolbox.framework
 
 
 grep  '-10851' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk/System/Library/Frameworks/AVFoundation.framework
 
 
 */


/*
 
 Turn into proper class
 
 
 tested so far :
    note on
    note off
    pitch bend (do we need it?)
    pan control (midi cntl #10)
    pitch control (midi cntl #2) 
    sampler start (midi cntl #1) mapped to sample start factor
 
 
 
better ui for testing
 
Multi Layers :
 
 Make one layer and then duplicate using code.
    aupreset has one layer
    duplicate to have 9 layers : one for each cell
    iter thru layers resetting min/max key and key offset
 
    Layers
        min & max = 10
        offset = 60 - min | max
 
    KBaseKey = 10
 
 
 
Note Off :
    test for logic : need to remember last note and turn it off

 
Envelope :
test for : attack / decay
 
 start to think
    what the relationship of the envelope
    previous model of what the attack/decay is
    envelope <-> length/time
 
 
 
 
 
 */

@end
