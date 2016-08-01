//
//  FlexibleInterfaceViewController.h
//  iOSAVRate
//
//  Created by Pierre on 19/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#include "PlaylistController.h"

@interface FlexibleInterfaceViewController : UIViewController<NSStreamDelegate> {

    NSMutableArray *sliders;
    NSMutableArray *groupSliderLabels;
    NSMutableArray *sliderCaption;
    
    NSMutableArray *buttonsCaption;
    NSMutableArray *buttons;
    UIView *clientView;

    UIButton *commit;
    NSMutableArray *filled;
    bool firstPlay;

    // ----------------------------------------
    // communication with server.
    NSInputStream *istream;
    NSOutputStream *ostream;
    bool setupNotInTime;
    
    // ----------------------------------------
    // play a video on the device.
    bool playOnDevice;
    MPMoviePlayerController *movie;
    NSString *seqName;
    
    // ----------------------------------------
    // play video from library
    NSArray *videosOnDeviceLibrary;
    PlaylistController *controler;
    NSString *logScores;

    
    
    IBOutlet UIButton *backButton;
    
}

- (void)        initNetwork;
- (void)        loadInterface;
- (void)        cleanupLayoutPortrait;
- (void)        cleanupLayoutLandscape;
- (void) didRotate:(NSNotification *)notification;
- (IBAction)    commitAndNext:(UIGestureRecognizer *)gestureRecognizer;
- (IBAction)    sliderClicked:(UIGestureRecognizer *)gestureRecognizer;
- (IBAction)    radioButtonBehaviour:(UIGestureRecognizer *)gestureRecognizer;
- (IBAction)    playVideoOnDevice;

-(void)         controlEnable:(BOOL) enable;
-(void)         sendScores;
-(void)         checkEnableCommit;
-(void)         resetInterface;
-(void)         endMenu;

@end
