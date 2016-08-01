//
//  ViewController.m
//  iOSAVRate
//
//  Created by Pierre on 16/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
// http://www.raywenderlich.com/3932/how-to-create-a-socket-based-iphone-app-and-server

#import "ViewController.h"
#import "Settings.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    image = [UIImage imageNamed:@"scales_all.jpg"];
    imageView = [[UIImageView alloc] initWithImage:image];
    
    CGRect rect = self.view.bounds;
    rect.size.height -= 120;
    rect.origin.y += 60;
    
    [endButton setBounds:CGRectMake(self.view.bounds.size.width*3, endButton.bounds.origin.y, endButton.bounds.size.width, endButton.bounds.size.height)];
    
    nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nextButton.frame = CGRectMake((self.view.bounds.size.width-250)/2, 10, 250, 40);
    [nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [nextButton setTitle:@"Please rate" forState:UIControlStateDisabled];
    nextButton.enabled = true;
    [nextButton setShowsTouchWhenHighlighted:TRUE];
    [nextButton addTarget:self action:@selector(nextPane) forControlEvents:UIControlEventTouchDown];
    
    [imageView setFrame:rect];
    
    [imageView setUserInteractionEnabled:TRUE];
    
    gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerOneTap:) ];
    
    [gesture setNumberOfTapsRequired:1];
    [gesture setNumberOfTouchesRequired:1];
    
    [imageView addGestureRecognizer:gesture];
    
    [self.view addSubview:imageView];
    [self.view addSubview:nextButton];
    [self initNetwork];
    [self loadInterface];
    
    for(int i = 0 ; i < 7 ; ++i)
        selected[i] = -1;
    
    firstPlay = true;
    [imageView setHidden:TRUE];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction) oneFingerOneTap:(UITapGestureRecognizer *) gestureRecognizer {
    // --------------------------------------------
    // Location boxes
    
    int XGRID[] = {95, 561, 979, 1425, 1891, 2404};
    int YGRID[] = {3, 365, 682, 1031, 1559, 1923, 2343, 2753};
    float xGridRatio = image.size.width / imageView.bounds.size.width;
    float yGridRatio = image.size.height / self.view.bounds.size.height;
    
    // --------------------------------------------
    // add selected
    
    CGPoint tap = [gestureRecognizer locationInView:self.view];
    tap.y = (tap.y-60) * (1+120/imageView.bounds.size.height);
//    NSLog(@"hello click: %f, %f", tap.x*xGridRatio, tap.y*yGridRatio);
    
    CGPoint tapInImage = CGPointMake(tap.x*xGridRatio, tap.y*yGridRatio);
    int level = 4;
    for(int i = 0 ; i < 5 ; ++i) {
        if (tapInImage.x > XGRID[i]) {
            level = i;
        }
    }
    if(tapInImage.x < XGRID[0])
        level = 0;
    
    int depthC = 7;
    for(int i = 0 ; i < 8 ; ++i) {
        if (tapInImage.y > YGRID[i]) {
            depthC = i;
        }
    }
    
    selected[depthC] = level;
    
//    NSLog(@"hello click: %d, %d", depthC, level);
    
    // --------------------------------------------
    // display
    
    
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [image drawInRect:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    CGColorRef redColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0].CGColor;
    CGContextSetStrokeColorWithColor(context, redColor);
    
    BOOL allScalesEvaluated = true;
    for(int i = 0 ; i < 7 ; ++i) {
        if(selected[i] == -1) {
            allScalesEvaluated = false;
            continue;
        }
        
        CGRect rect;
        rect.size.height = (YGRID[i+1]-YGRID[i])/yGridRatio - 10;
        rect.size.width = (XGRID[selected[i]+1]-XGRID[selected[i]])/xGridRatio - 10;

        rect.origin.x = XGRID[selected[i]]/xGridRatio+5;
        rect.origin.y = YGRID[i]/yGridRatio+5;
    
        CGContextStrokeRect(context, rect);
    }
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [imageView setImage:resultImage];
    
    
    if(allScalesEvaluated) {
        nextButton.enabled = TRUE;
        
    }
}


- (void) initNetwork {
    Settings *settings = [Settings get];
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef) settings.ipServer, 8080, &readStream, &writeStream);
    
    istream = objc_unretainedObject(readStream);
    ostream = objc_unretainedObject(writeStream);
    
    [istream setDelegate:self];
    [ostream setDelegate:self];
    
    // schedule a task, so it keep the TCP connection open.
    [istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [istream open];
    [ostream open];
    
}

-(void) loadInterface {
    uint8_t buffer[1024];
    
    NSString *xmlData = @"";
    while(TRUE) {
        int len = [istream read:buffer maxLength:sizeof(buffer)];
        
        NSString *line = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
        
        if(len > 0)
            xmlData = [xmlData stringByAppendingString:[line substringToIndex:len]];
        
        if(len != sizeof(buffer))
            break;
        
        
    }
    NSLog(@"%@\n", xmlData);
    
}

-(void) sendScores {
    
    NSString *response = @"[Scores]";
    for(int i = 0 ; i < 7 ; ++i) {
        response = [[response stringByAppendingString:[NSString stringWithFormat:@"%3.3d", selected[i]]] stringByAppendingString:@", "];
    }
    response = [response stringByAppendingString:@"[/Scores]"];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [ostream write:[data bytes] maxLength:[data length]];
    
    for(int i = 0 ; i < 7 ; ++i)
        selected[i] = -1;
    
}

-(void) playNextVideo {
    NSString *response = @"[PLAY]";
    NSLog(@"PLAY SENT");
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [ostream write:[data bytes] maxLength:[data length]];
    
    uint8_t buffer[1024];
    int len = [istream read:buffer maxLength:sizeof(buffer)];
    response = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
    
    if((response.length >= 12) && [[response substringToIndex:10] isEqual:@"[RELEASEGUI]"] == TRUE) {
        NSLog(@"OK, now we can continue...");
    }
    
}


- (IBAction) nextPane {

    if(firstPlay) {
        
        firstPlay = false;
        [self playNextVideo];
        
        [imageView setHidden:FALSE];
        [nextButton setEnabled:FALSE];
        
        return;
        
    } else {
        
        [self sendScores];
        
        
        uint8_t buffer[1024];
        int len = [istream read:buffer maxLength:sizeof(buffer)];
        NSString *response = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
        
        
        if(response.length >= 10 && [[response substringToIndex:10] isEqual:@"[CONTINUE]"] == TRUE) {
            
            [UIView animateWithDuration:0.6 animations:^{
                
                [imageView setFrame:CGRectMake(-imageView.frame.size.width, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height)];
            }
                             completion:^(BOOL finished) {
                                 
                                 [imageView setFrame:CGRectMake(0, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height)];
                                 nextButton.enabled = FALSE;
                                 [imageView setImage:image];
                                 
                                 [self playNextVideo];
                                 
                             }
             ];
            
        } else if (response.length >= 6 && [[response substringToIndex:6] isEqual:@"[DONE]"] == TRUE) {
            NSLog(@"Try to go back!");
            [imageView setFrame:CGRectMake(-imageView.frame.size.width, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height)];
            [endButton setBounds:CGRectMake((imageView.frame.size.width-endButton.bounds.size.width)/2.0-250, endButton.bounds.origin.y, endButton.bounds.size.width, endButton.bounds.size.height)];
            nextButton.enabled = false;
        }
    
    }
    
    
    
}




@end
