//
//  FlexibleInterfaceViewController.m
//  iOSAVRate
//
//  Created by Pierre on 19/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import "FlexibleInterfaceViewController.h"
#import "Settings.h"
#import "SMXMLDocument.h"


@interface FlexibleInterfaceViewController ()

@end

@implementation FlexibleInterfaceViewController {
    
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    sliders = [[NSMutableArray alloc] init];
    buttons = [[NSMutableArray alloc] init];
    groupSliderLabels = [[NSMutableArray alloc] init];
    sliderCaption = [[NSMutableArray alloc] init];
    buttonsCaption = [[NSMutableArray alloc] init];
    filled = [[NSMutableArray alloc] init];
    
    setupNotInTime = false;
    playOnDevice = false;
    firstPlay = true;
    
    clientView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:clientView];

    
    // Add a commit button !
    commit = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    commit.frame = CGRectMake((self.view.bounds.size.width-300)/2, (self.view.bounds.size.height-60), 300, 50);
    [commit setTitle:@"Play" forState:UIControlStateNormal];
    [commit setTitle:@"Play" forState:UIControlStateDisabled];
    commit.backgroundColor = [UIColor colorWithRed:0.11 green:0.79 blue:0.42 alpha:1];
    [commit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:commit];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commitAndNext:)];
    [commit addGestureRecognizer:tapGestureRecognizer];
    
    // load settings from network!
    
    Settings *settings = [Settings get];
    
    if([settings.standalone boolValue] == FALSE) {
        [self initNetwork];
    }
    [self loadInterface];
    
    
    if([settings.standalone boolValue]) {
        logScores = @"";
        
        if([settings.xmlViewSettings isEqualToString:@""])
            setupNotInTime = true;
        else
            setupNotInTime = false;
        
        MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMovie] forProperty:MPMediaItemPropertyMediaType];
        
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:predicate];
        
        videosOnDeviceLibrary = [query items];
        
        controler = [[PlaylistController alloc] initWithPlaylist:videosOnDeviceLibrary.count :settings.trainingList];
    }
    
    
    
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPhone"] || [deviceType isEqualToString:@"iPod"] || [deviceType isEqualToString:@"iPhone Simulator"])
        [self cleanupLayoutPortrait];
    else if ([deviceType isEqualToString:@"iPad"])
        [self cleanupLayoutLandscape];
    else
        [self cleanupLayoutLandscape];
    
    
    
    [backButton setTitle:@"Return" forState:UIControlStateNormal];
    [backButton setTitle:@"Return" forState:UIControlStateDisabled];
    [clientView addSubview:backButton];
    
    if(setupNotInTime) {
        
        UILabel *configurationAlert;
        if([deviceType isEqualToString:@"iPhone"] || [deviceType isEqualToString:@"iPod"] || [deviceType isEqualToString:@"iPhone Simulator"])
            configurationAlert = [[UILabel alloc] initWithFrame:CGRectMake(30, clientView.frame.size.height/2-130, clientView.frame.size.width-60, 120)];
        else
            configurationAlert = [[UILabel alloc] initWithFrame:CGRectMake(30, clientView.frame.size.width/2, clientView.frame.size.height-60, 50)];
        
        if([settings.standalone boolValue])
            [configurationAlert setText:@"Device is in standalone mode, however no local settings are found. Please apply settings using AVRate server in the settings menu..."];
        else
            [configurationAlert setText:@"Cannot connet to AVRate server, please check IP settings and make sure that AVRate is already running and waiting for the mobile device..."];
        configurationAlert.numberOfLines = 0;
        [clientView addSubview:configurationAlert];
        
        [commit setHidden:TRUE];
        
    } else {
        [backButton setHidden:TRUE];
    }
    
    
    seqName = @"moon_walk";
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(didRotate:)
                                                name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    
    [self controlEnable:false];
    [commit setEnabled:true];
    
    
}


- (void) didRotate:(NSNotification *)notification{
    return;
    
    
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait)  {
        [self cleanupLayoutPortrait];
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
        [self cleanupLayoutLandscape];
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
        [self cleanupLayoutLandscape];
    } else {
        [self cleanupLayoutPortrait];
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    Settings *settings = [Settings get];
    
    NSData* data;
    if ([settings.standalone boolValue]) {
        data=[settings.xmlViewSettings dataUsingEncoding: [NSString defaultCStringEncoding] ];
        
    } else {
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
        data=[xmlData dataUsingEncoding: [NSString defaultCStringEncoding] ];
    }
    
    
    
    
    NSError *error;
    SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&error];
    
    if (error) {
        setupNotInTime = true;
        return;
    }
    
    SMXMLElement *xmlSettings = document.root;
    
    for (SMXMLElement *sl in [xmlSettings childrenNamed:@"playondevice"]) {
        playOnDevice = [[sl value] isEqualToString:@"true"];
    }
    
    // Go through every sub-element "video"
    int GraphicalElement = 0;
    int SliderHEIGHT = 280;
    for (SMXMLElement *sl in [xmlSettings childrenNamed:@"slider"]) {
        [filled addObject:[NSNumber numberWithInt:0]];
        
        
        // min / max / shownumbers
        bool shownumer = [[sl valueWithPath:@"shownumbers"] isEqualToString:@"true"];
        int minV = [[sl valueWithPath:@"min"] intValue];
        int maxV = [[sl valueWithPath:@"max"] intValue];
                
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/40, 10 + GraphicalElement*SliderHEIGHT, 300, 30)];
        [label setText: [sl valueWithPath:@"name"]];
        [sliderCaption addObject:label];
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/40, 40 + GraphicalElement*SliderHEIGHT+30*shownumer, self.view.frame.size.width*37.5/40, 30)];
        [slider setMinimumValue:minV];
        [slider setMaximumValue:maxV];
        
        
        [clientView addSubview:slider];
        [clientView addSubview:label];

        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderClicked:)];
        [slider addGestureRecognizer:tapGestureRecognizer];
        
        
        
        
        NSMutableArray *sliderLabels = [[NSMutableArray alloc] init];
        NSMutableArray *sliderNumLabels = [[NSMutableArray alloc] init];
        int count = 0;
        for(SMXMLElement *lab in [sl childrenNamed:@"label"]) {
            
            UILabel *localLabel = [[UILabel alloc] initWithFrame:CGRectMake(30*(++count), slider.frame.origin.y+slider.frame.size.height+30, 80, 20)];
            [localLabel setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
            [localLabel setText:[lab value]];
            
            [sliderLabels addObject:localLabel];
        }
        
        for (int i = 0; i < sliderLabels.count; ++i) {
            UILabel *localLabel = [sliderLabels objectAtIndex:i];
            [localLabel setFrame:CGRectMake(slider.frame.origin.x+(slider.frame.size.width-20)/(sliderLabels.count-1)*i, localLabel.frame.origin.y, localLabel.frame.size.width, localLabel.frame.size.height)];
            
            [clientView addSubview:localLabel];
            
            if(shownumer) {
                UILabel *numLabel = [[UILabel alloc] initWithFrame:CGRectMake(slider.frame.origin.x+(slider.frame.size.width-10)/(sliderLabels.count-1)*i, slider.frame.origin.y-30, 30, 30)];
                int v = (float)((i+1)*(maxV-minV)) / ((float)(sliderLabels.count))+minV;
                [numLabel setText:[NSString stringWithFormat:@"%d", v]];
                [sliderNumLabels addObject:numLabel];
                [clientView addSubview:numLabel];
            }
            
        }
        
        [groupSliderLabels addObject:sliderLabels];
        [groupSliderLabels addObject:sliderNumLabels];
        
        
        ++GraphicalElement;
        [sliders addObject:slider];
                
    }
    

    for (SMXMLElement *sl in [xmlSettings childrenNamed:@"buttons"]) {
        [filled addObject:[NSNumber numberWithInt:0]];
        
        UILabel *buttonGroupLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/40 + 300*buttons.count, GraphicalElement*SliderHEIGHT-40, 100, 30)];
        [buttonGroupLabel setText:[sl valueWithPath:@"name"]];
        [clientView addSubview:buttonGroupLabel];
        [buttonsCaption addObject:buttonGroupLabel];
        
        int nbRadioButtons = buttons.count;
        NSMutableArray *buttonsGroup = [[NSMutableArray alloc] init];
        [buttons addObject:buttonsGroup];
        
        for(SMXMLElement *lab in [sl childrenNamed:@"label"]) {
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            button.frame = CGRectMake(10+nbRadioButtons*300, GraphicalElement*SliderHEIGHT+60*buttonsGroup.count, 250, 50);
            //button.backgroundColor = [UIColor colorWithRed:0.11 green:0.79 blue:0.42 alpha:1]; // green
            //button.backgroundColor = [UIColor colorWithRed:0.79 green:0.27 blue:0.44 alpha:1]; // red
            button.backgroundColor = [UIColor colorWithRed:0.60 green:0.75 blue:0.72 alpha:1]; //
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
            
            [button setTitle:[lab value] forState:UIControlStateNormal];
            [button setTitle:[lab value] forState:UIControlStateDisabled];
            
            [buttonsGroup addObject:button];
            
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(radioButtonBehaviour:)];
            [button addGestureRecognizer:tapGestureRecognizer];
            
            
            [clientView addSubview:button];
        }

    }
    
}


// once all elements are loaded it is possible to align all GUI elements
-(void) cleanupLayoutPortrait {
    int SliderHEIGHT = 280;
    
    int NBGroupButtons = buttons.count;
    int NBSliders = sliders.count;
    
    int mxButtonPerGroup = 0;
    for(int i = 0 ; i < NBGroupButtons ; ++i) {
        NSMutableArray *buttonG = [buttons objectAtIndex:i];
        
        if(mxButtonPerGroup < buttonG.count)
            mxButtonPerGroup = buttonG.count;
    }
    
    
    float verticalSpaceRemaining = self.view.bounds.size.height - SliderHEIGHT*NBSliders - mxButtonPerGroup*30 - 10 - 300 + 50;
    int spacing = verticalSpaceRemaining / (NBSliders + MIN(1, NBGroupButtons) + 1);
    
    // Update vertical position of all elements!
    for(int i = 0 ; i < NBSliders ; ++i) {
        
        UISlider *slider = [sliders objectAtIndex:i];
        float WSpacing = slider.frame.origin.x - (self.view.bounds.size.width - slider.frame.size.width) / 2;
        
        float offsetH = 100+(i+1)*spacing+i*SliderHEIGHT - slider.frame.origin.y;
        //NSLog(@"%f", slider.frame.origin.y+offsetH);
        [slider setFrame:CGRectMake(slider.frame.origin.x+WSpacing, slider.frame.origin.y+offsetH, slider.frame.size.width, slider.frame.size.height)];
        
        UILabel *aLabel = [sliderCaption objectAtIndex:i];
        [aLabel setFrame:CGRectMake(aLabel.frame.origin.x+WSpacing, aLabel.frame.origin.y+offsetH, aLabel.frame.size.width, aLabel.frame.size.height)];

        for(int n = 2*i ; n < (2*i+2) ; ++n) {
            NSMutableArray *labels = [groupSliderLabels objectAtIndex:n];
            for(int k = 0 ; k < labels.count ; ++k) {
                UILabel *aLabel = [labels objectAtIndex:k];
                [aLabel setFrame:CGRectMake(aLabel.frame.origin.x+WSpacing, aLabel.frame.origin.y+offsetH, aLabel.frame.size.width, aLabel.frame.size.height)];
            }
        }
    }

    float WSpacing = (self.view.frame.size.width - NBGroupButtons*250) / (NBGroupButtons + 1);
    for(int i = 0 ; i < NBGroupButtons ; ++i) {
        NSMutableArray *buttonG = [buttons objectAtIndex:i];
        UIButton *b = [buttonG objectAtIndex:0];
        
        int offsetH = 50+(NBSliders+1)*spacing+NBSliders*SliderHEIGHT - b.frame.origin.y;
        int offsetW = (i+1)*WSpacing+i*300 - b.frame.origin.x;
        
        UILabel *aLabel = [buttonsCaption objectAtIndex:i];
        [aLabel setFrame:CGRectMake(aLabel.frame.origin.x+offsetW, aLabel.frame.origin.y+offsetH, aLabel.frame.size.width, aLabel.frame.size.height)];
        
        
        for(int n = 0 ; n < buttonG.count ; ++n) {
            UIButton *b = [buttonG objectAtIndex:n];
            
            
            
            [b setFrame:CGRectMake(b.frame.origin.x+offsetW, b.frame.origin.y+offsetH, b.frame.size.width, b.frame.size.height)];
        }
    }
    
    commit.frame = CGRectMake((self.view.bounds.size.width-300)/2, (self.view.bounds.size.height-60), 300, 50);
    
}


// once all elements are loaded it is possible to align all GUI elements
-(void) cleanupLayoutLandscape {
    int SliderHEIGHT = 280;
    
    int NBGroupButtons = buttons.count;
    int NBSliders = sliders.count;
    
    int mxButtonPerGroup = 0;
    for(int i = 0 ; i < NBGroupButtons ; ++i) {
        NSMutableArray *buttonG = [buttons objectAtIndex:i];
        
        if(mxButtonPerGroup < buttonG.count)
            mxButtonPerGroup = buttonG.count;
    }
    
    
    float verticalSpaceRemaining = self.view.frame.size.height - SliderHEIGHT*NBSliders - mxButtonPerGroup*30 - 10 - 300;
    
    int spacing = verticalSpaceRemaining / (NBSliders + MIN(1, NBGroupButtons) + 1);
    
    // Update vertical position of all elements!
    for(int i = 0 ; i < NBSliders ; ++i) {
        UISlider *slider = [sliders objectAtIndex:i];
        
        float WSpacing = (self.view.bounds.size.width - slider.frame.size.width) / 2 - 40;
        
        float offsetH = 100+(i+1)*spacing+i*SliderHEIGHT - slider.frame.origin.y;
        //NSLog(@"%f", slider.frame.origin.y+offsetH);
        [slider setFrame:CGRectMake(slider.frame.origin.x+WSpacing, slider.frame.origin.y+offsetH, slider.frame.size.width, slider.frame.size.height)];
        
        UILabel *aLabel = [sliderCaption objectAtIndex:i];
        [aLabel setFrame:CGRectMake(aLabel.frame.origin.x+WSpacing, aLabel.frame.origin.y+offsetH, aLabel.frame.size.width, aLabel.frame.size.height)];
        
        for(int n = 2*i ; n < (2*i+2) ; ++n) {
            NSMutableArray *labels = [groupSliderLabels objectAtIndex:n];
            for(int k = 0 ; k < labels.count ; ++k) {
                UILabel *aLabel = [labels objectAtIndex:k];
                [aLabel setFrame:CGRectMake(aLabel.frame.origin.x+WSpacing, aLabel.frame.origin.y+offsetH, aLabel.frame.size.width, aLabel.frame.size.height)];
            }
        }
    }
    
    float WSpacing = (self.view.bounds.size.width - NBGroupButtons*250) / (NBGroupButtons + 1);
    for(int i = 0 ; i < NBGroupButtons ; ++i) {
        NSMutableArray *buttonG = [buttons objectAtIndex:i];
        UIButton *b = [buttonG objectAtIndex:0];
        
        int offsetH = 50+(NBSliders+1)*spacing+NBSliders*SliderHEIGHT - b.frame.origin.y;
        int offsetW = (i+1)*WSpacing+i*300 - b.frame.origin.x;
        
        UILabel *aLabel = [buttonsCaption objectAtIndex:i];
        [aLabel setFrame:CGRectMake(aLabel.frame.origin.x+offsetW, aLabel.frame.origin.y+offsetH, aLabel.frame.size.width, aLabel.frame.size.height)];
        
        
        for(int n = 0 ; n < buttonG.count ; ++n) {
            UIButton *b = [buttonG objectAtIndex:n];
            
            
            
            [b setFrame:CGRectMake(b.frame.origin.x+offsetW, b.frame.origin.y+offsetH, b.frame.size.width, b.frame.size.height)];
        }
    }
    
    commit.frame = CGRectMake((self.view.bounds.size.width-300)/2, (self.view.bounds.size.height-60), 300, 50);
    
    
}


- (IBAction)    sliderClicked:(UIGestureRecognizer *)gestureRecognizer {
    UISlider* s = (UISlider*)gestureRecognizer.view;
    if (s.highlighted)
        return; // tap on thumb, let slider deal with it
    CGPoint pt = [gestureRecognizer locationInView: s];
    CGFloat percentage = pt.x / s.bounds.size.width;
    CGFloat delta = percentage * (s.maximumValue - s.minimumValue);
    CGFloat value = s.minimumValue + delta;
    [s setValue:value animated:YES];
    
    
    for(int i = 0 ; i < sliders.count ; ++i) {
        if(s == [sliders objectAtIndex:i]) {
            [filled replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:100]];
        }
    }
    
    [self checkEnableCommit];
}

- (void)highlightButton:(UIButton *)b {
    [b setHighlighted:YES];
}



// simulate radio buttons...
- (IBAction)    radioButtonBehaviour:(UIGestureRecognizer *)gestureRecognizer {
    UIButton* b =(UIButton*) gestureRecognizer.view;
    
    
    int radGIndex = -1;
    for(int i = 0 ; i < buttons.count ; ++i) {
        NSMutableArray *radioG = [buttons objectAtIndex:i];
        for (int n = 0 ; n < radioG.count ; ++n) {
            UIButton *bn = [radioG objectAtIndex:n];
            
            if(bn == b) {
                radGIndex = i;
                [filled replaceObjectAtIndex:(i+sliders.count) withObject:[NSNumber numberWithInt:100]];
                break;
            }
        }
        
        if(radGIndex != -1)
            break;
    }
    
    NSMutableArray *radioG = [buttons objectAtIndex:radGIndex];
    for(int i = 0 ; i < radioG.count ; ++i) {
        UIButton *bn = [radioG objectAtIndex:i];
        
        [bn setSelected:FALSE];
        [bn setHighlighted:FALSE];
    }
    
    [self performSelector:@selector(highlightButton:) withObject:b afterDelay:0.0];
    
    [self checkEnableCommit];
}





-(void)         checkEnableCommit {
    bool allfilled = true;
    for(int i = 0 ; i < filled.count ; ++i) {
        NSNumber *num = [filled objectAtIndex:i];
        
        if([num integerValue] != 100) {
            allfilled = false;
        }
    }
    
    if(allfilled)
        [commit setEnabled:true];
}





-(void)         resetInterface {
    for(int i = 0 ; i < filled.count ; ++i) {
        [filled replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
    }
    
    for(int i = 0 ; i < sliders.count ; ++i) {
        UISlider *slider = [sliders objectAtIndex:i];
        [slider setValue:[slider minimumValue]];
    }
    
    for(int i = 0 ; i < buttons.count ; ++i) {
        NSMutableArray *buttonG = [buttons objectAtIndex:i];
        
        for(int n = 0 ; n < buttonG.count ; ++n) {
            UIButton *b = [buttonG objectAtIndex:n];
            [b setHighlighted:false];
        }
    }
    
    [commit setEnabled:false];
}



-(void) endMenu {
    // Update vertical position of all elements!
    for(int i = 0 ; i < sliders.count ; ++i) {
        UISlider *slider = [sliders objectAtIndex:i];
        [slider setHidden:TRUE];
        
        UILabel *aLabel = [sliderCaption objectAtIndex:i];
        [aLabel setHidden:TRUE];
                
        for(int n = 2*i ; n < (2*i+2) ; ++n) {
            NSMutableArray *labels = [groupSliderLabels objectAtIndex:n];
            for(int k = 0 ; k < labels.count ; ++k) {
                UILabel *aLabel = [labels objectAtIndex:k];
                [aLabel setHidden:TRUE];
            }
        }
    }
    
    for(int i = 0 ; i < buttons.count ; ++i) {
        NSMutableArray *buttonG = [buttons objectAtIndex:i];
        UIButton *b = [buttonG objectAtIndex:0];
        [b setHidden:TRUE];
        
        UILabel *aLabel = [buttonsCaption objectAtIndex:i];
        [aLabel setHidden:TRUE];
        
        for(int n = 0 ; n < buttonG.count ; ++n) {
            UIButton *b = [buttonG objectAtIndex:n];
            
            [b setHidden:TRUE];
        }
    }
    
    UILabel *configurationAlert;
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPhone"] || [deviceType isEqualToString:@"iPod"] || [deviceType isEqualToString:@"iPhone Simulator"])
        configurationAlert = [[UILabel alloc] initWithFrame:CGRectMake(30, clientView.frame.size.width/2-130, clientView.frame.size.width-60, 120)];
    else
        configurationAlert = [[UILabel alloc] initWithFrame:CGRectMake(clientView.frame.size.width/2-200, clientView.frame.size.width/2, clientView.frame.size.height-60, 50)];
    [configurationAlert setText:@"Evaluation is finished. Thank you for participating!"];
    configurationAlert.numberOfLines = 0;
    [clientView addSubview:configurationAlert];
    

    [commit setHidden:TRUE];
    [backButton setHidden:FALSE];
    
    
    // if mode standalone, then it is time to save the scores on the device
    [self saveScoresToFile];

}

-(void) saveScoresToFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *newDirectory = [NSString stringWithFormat:@"%@/Scores", [paths objectAtIndex:0]];
    
    // Check if the directory already exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:newDirectory]) {
        // Directory does not exist so create it
        [[NSFileManager defaultManager] createDirectoryAtPath:newDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    // ----------------------------------------
    // list existing files...
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:newDirectory error:NULL];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/Log%3.3d.csv",
                          newDirectory, directoryContent.count+1];

    // ----------------------------------------
    //save content to the documents directory
    [logScores  writeToFile:fileName
                atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                error:nil];
    
    logScores = @"";
    
}


-(void) playNextVideo {
    Settings *settings = [Settings get];
    
    if([settings.standalone boolValue]) {
        [controler next];
        
        if([controler currentOnePlayable])
            [self playVideoOnDevice];
        
    } else {
    
        if(!playOnDevice) {
            
            NSString *response = @"[PLAY]";
            NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
            [ostream write:[data bytes] maxLength:[data length]];
            
            uint8_t buffer[1024];
            int len = [istream read:buffer maxLength:sizeof(buffer)];
            seqName = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
            
            if((response.length >= 12) && [[response substringToIndex:10] isEqual:@"[RELEASEGUI]"] == TRUE) {
                NSLog(@"OK, now we can continue...");
            }
            
            
        } else {
            
            NSString *response = @"[NEXT2PLAY]";
            NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
            [ostream write:[data bytes] maxLength:[data length]];
            
            firstPlay = false;
            
            [self controlEnable:true];
            [commit setEnabled:false];
            
            uint8_t buffer[1024];
            int len = [istream read:buffer maxLength:sizeof(buffer)];
            seqName = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
            
            [self playVideoOnDevice];
            
        }
    }
    
}

- (IBAction)    commitAndNext:(UIGestureRecognizer *)gestureRecognizer {
    
    
    if(firstPlay) {
        
        firstPlay = false;
        [self playNextVideo];
        
        
        [self controlEnable:true];
        [commit setEnabled:false];
        return;
        
    } else {
        
        
        [self sendScores];
    
        uint8_t buffer[1024];
        int len = [istream read:buffer maxLength:sizeof(buffer)];
        NSString *response = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
        
        bool continueEvaluation = false;
        Settings *settings = [Settings get];
        
        if([settings.standalone boolValue]) {
            continueEvaluation = ![controler endOfPlaylist];
        } else {
           continueEvaluation = (response.length >= 10) && [[response substringToIndex:10] isEqual:@"[CONTINUE]"] == TRUE;
        }
    
    
        if(continueEvaluation) {
        
            [UIView animateWithDuration:0.6 animations:^{
            
                [clientView setFrame:CGRectMake(-self.view.frame.size.width, self.view.frame.origin.y, self.view.frame.size.height, self.view.frame.size.width)];
                
                } completion:^(BOOL finished) {
                             
                    [clientView setFrame:CGRectMake(0, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
                    commit.enabled = FALSE;
                
                    [self resetInterface];
                    [self controlEnable:true];

                    [self playNextVideo];
                    
                    
                    [self controlEnable:true];
                    [commit setEnabled:false];
                             
            }];
        
        } else {
            
            [self endMenu];
        }
    }
}


-(void)         controlEnable:(BOOL) enable {
    for(int i = 0 ; i < sliders.count ; ++i) {
        UISlider *slider = [sliders objectAtIndex:i];
        [slider setEnabled:enable];
    }
    
    for(int i = 0 ; i < buttons.count ; ++i) {
        NSMutableArray *buttonG = [buttons objectAtIndex:i];
        
        for(int n = 0 ; n < buttonG.count ; ++n) {
            UIButton *b = [buttonG objectAtIndex:n];
            [b setEnabled:enable];
        }
    }
}


-(void)         sendScores {
    
    if(firstPlay) {
        return;
    }
    
    Settings *settings = [Settings get];
    
    if([settings.standalone boolValue]) {
        // Store on device...
        
        MPMediaItem* item = [videosOnDeviceLibrary objectAtIndex:[controler getCurrent]];
        
        logScores = [logScores stringByAppendingString:[item valueForProperty:MPMediaItemPropertyTitle]];
        for(int i = 0 ; i < sliders.count ; ++i) {
            UISlider *slider = [sliders objectAtIndex:i];
            
            logScores = [logScores stringByAppendingString:[NSString stringWithFormat:@", %f", slider.value]];
        }
        
        for(int i = 0 ; i < buttons.count ; ++i) {
            NSMutableArray *buttonG = [buttons objectAtIndex:i];
            
            for(int n = 0 ; n < buttonG.count ; ++n) {
                UIButton *b = [buttonG objectAtIndex:n];
                if(b.highlighted) {
                    logScores = [logScores stringByAppendingString:[NSString stringWithFormat:@", %d ", n]];
                }
            }
        }
        logScores = [logScores stringByAppendingString:@"\n"];
        
        
    } else {
        // Send score though network...
        
        NSString *response = @"[Scores]";
        for(int i = 0 ; i < sliders.count ; ++i) {
            UISlider *slider = [sliders objectAtIndex:i];
            
            response = [response stringByAppendingString:[NSString stringWithFormat:@"%f, ", slider.value]];
        }
        
        for(int i = 0 ; i < buttons.count ; ++i) {
            NSMutableArray *buttonG = [buttons objectAtIndex:i];
            
            for(int n = 0 ; n < buttonG.count ; ++n) {
                UIButton *b = [buttonG objectAtIndex:n];
                if(b.highlighted) {
                    response = [response stringByAppendingString:[NSString stringWithFormat:@"%d, ", n]];
                }
            }
        }
        
        response = [response stringByAppendingString:@"[/Scores]"];
        NSLog(@"%@", response);
        
        NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
        [ostream write:[data bytes] maxLength:[data length]];

    }
    
}

- (IBAction)   playVideoOnDevice {
    
    Settings *settings = [Settings get];
    
	if(seqName == NULL){
		return;
	}
	
	NSURL *videoURL;
    if([settings.standalone boolValue]) {
        
        MPMediaItem* item = [videosOnDeviceLibrary objectAtIndex:[controler getCurrent]];
        videoURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        
    } else {
        videoURL = [NSURL URLWithString:seqName];
    }
	
    movie = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playbackFinishedCallback:)
												 name:MPMoviePlayerPlaybackDidFinishNotification
											   object:movie];
	
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPhone"] || [deviceType isEqualToString:@"iPod"] || [deviceType isEqualToString:@"iPhone Simulator"]) {
        [[movie view] setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    }
    
    [[movie view] setFrame:[[self view] bounds]];
    [[self view] addSubview: [movie view]];
   
    
    movie.scalingMode = MPMovieScalingModeAspectFit;
    movie.controlStyle = MPMovieControlStyleNone;
	// [movie setFullscreen:YES animated:NO]; // if set, quit landscape mode on iPhone and do not hide the clock anyway...
    
    movie.movieSourceType = MPMovieSourceTypeFile;
    [movie prepareToPlay];
    
    
	[movie play];
}


-(void) playbackFinishedCallback:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:MPMoviePlayerPlaybackDidFinishNotification
												  object:movie];
    [movie setFullscreen:NO];
    [movie.view removeFromSuperview];
    

}



@end
