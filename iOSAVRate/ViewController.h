//
//  ViewController.h
//  iOSAVRate
//
//  Created by Pierre on 16/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<NSStreamDelegate>{
    // ----------------------------------------
    // Test interface.
    
    UIImage *image;
    UIImageView *imageView;
    UITapGestureRecognizer *gesture;
    UIButton *nextButton;
    
    int selected[7];
    bool firstPlay;
    
    
    // ----------------------------------------
    // communication with server.
    NSInputStream *istream;
    NSOutputStream *ostream;
    
    // -----------------------------------------
    // end test
    
    IBOutlet UIButton *endButton;
    
}

- (IBAction)    oneFingerOneTap:(UITapGestureRecognizer *) gestureRecognizer;
- (IBAction)    nextPane;
- (void)        initNetwork;



@end
