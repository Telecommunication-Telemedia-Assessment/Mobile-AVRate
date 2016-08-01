//
//  SettingsViewController.m
//  iOSAVRate
//
//  Created by Pierre on 19/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import "SettingsViewController.h"
#import "Settings.h"
#import "SMXMLDocument.h"
#import <MediaPlayer/MediaPlayer.h>


@interface Sliders : NSObject {
    int max;
    int min;
    bool showNumber;
    
    NSString *title;
    NSMutableArray *labels;
}

@property (nonatomic) int max;
@property (nonatomic) int min;
@property (nonatomic) bool showNumber;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *labels;

@end

@implementation Sliders
@synthesize title;
@synthesize max;
@synthesize min;
@synthesize showNumber;
@synthesize labels;
@end

@interface ButtonGroup : NSObject {
    NSString *title;
    NSMutableArray *labels;
}
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *labels;

@end

@implementation ButtonGroup
@synthesize title;
@synthesize labels;
@end


@interface SettingsViewController () {
    bool isPhone;
}

@end

@implementation SettingsViewController



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
    delScores = [[DelegateDeleteScores alloc] init];
    delPlaylists = [[DelegateDeletePlaylists alloc] init];
    
    menuTabData = [NSArray arrayWithObjects:@"General Settings", @"Standalone", @"Set interface", nil];
    menuS = GeneralSettings;

    
    serverIP = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
    serverIP.adjustsFontSizeToFitWidth = YES;
    serverIP.textColor = [UIColor blackColor];
    serverIP.placeholder = @"Please provide the server ip/name";
    serverIP.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    serverIP.textAlignment = NSTextAlignmentRight;
    serverIP.returnKeyType = UIReturnKeyNext;
    serverIP.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
    serverIP.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
    serverIP.tag = 0;
    
    [serverIP setEnabled: YES];
    [serverIP addTarget:self action:@selector(commitSettings:) forControlEvents:UIControlEventEditingDidEnd];
    
    
    playFromLibrary = [[UISwitch alloc] initWithFrame:CGRectZero];
    [playFromLibrary addTarget:self action:@selector(commitSettings:) forControlEvents:UIControlEventValueChanged];
    
    loadSettingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [loadSettingButton addTarget:self action:@selector(loadStandAloneSettings) forControlEvents:UIControlEventTouchUpInside];
    [loadSettingButton setTitle:@"Load Settings" forState:UIControlStateNormal];
    [loadSettingButton setTitle:@"Load setting need standalone mode ON" forState:UIControlStateDisabled];
    
    
    sendScoreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendScoreButton addTarget:self action:@selector(openMail:) forControlEvents:UIControlEventTouchUpInside];
    [sendScoreButton setTitle:@"Send scores by email" forState:UIControlStateNormal];
    
    clearScoresButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [clearScoresButton addTarget:self action:@selector(deleteScores) forControlEvents:UIControlEventTouchUpInside];
    [clearScoresButton setTitle:@"Clear scores" forState:UIControlStateNormal];
    
    clearPlaylistButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [clearPlaylistButton addTarget:self action:@selector(deletePlaylists) forControlEvents:UIControlEventTouchUpInside];
    [clearPlaylistButton setTitle:@"Clear playlists" forState:UIControlStateNormal];
    
    // -------------------------------------------------------------
    // customize interface
    
    mySliders = [[NSMutableArray alloc] init];
    myButtonGroups = [[NSMutableArray alloc] init];
    [self parseSettingFile];
    
    
    // -------------------------------------------------------------
    // Set old configuration
    
    Settings *settings = [Settings get];
    
    [serverIP setText:settings.ipServer];
    [playFromLibrary setOn:[settings.standalone boolValue]];
    [loadSettingButton setEnabled:[settings.standalone boolValue]];
    
    
    // List video sequences on the device...
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMovie] forProperty:MPMediaItemPropertyMediaType];
    
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query addFilterPredicate:predicate];
    
    videosOnDeviceLibrary = [query items];
    
    
    
    
    // --------------------------------------------------------------
    // in case of an iPhone, access to main setting via swipe.
    
    isPhone = false;
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPhone"] || [deviceType isEqualToString:@"iPod"] || [deviceType isEqualToString:@"iPhone Simulator"]) {
        UIPanGestureRecognizer *oneFingerSwipeRight = [[UIPanGestureRecognizer alloc]
                                                         initWithTarget:self
                                                         action:@selector(oneFingerSwipeRight:)];
        [oneFingerSwipeRight setMinimumNumberOfTouches:1];
        [oneFingerSwipeRight setMaximumNumberOfTouches:1];
        
        [settingTableView addGestureRecognizer:oneFingerSwipeRight];
        isPhone = true;
    }
    
}

- (void)oneFingerSwipeRight:(id)sender {
    static CGPoint startLocation;
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        startLocation = [(UIPanGestureRecognizer*)sender translationInView:self.view];
        if(startLocation.x < 10)
            doPanAnimation = true;
        else
            doPanAnimation = false;
    }
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateChanged) {
        
        if(!doPanAnimation)
            return;
        
        CGPoint stopLocation = [(UIPanGestureRecognizer*)sender translationInView:self.view];
        
        if(abs(startLocation.x - stopLocation.x) < abs(startLocation.y - stopLocation.y)) {
            UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer*)sender;
            
            
        }
            
        
        if(deployed) {
            stopLocation.x += settingTableView.frame.size.width-100;
        }
        
        if(stopLocation.x > settingTableView.frame.size.width-100) {
            stopLocation.x = settingTableView.frame.size.width-100;
        }
        
        if(stopLocation.x < 0)
            return;
        

        [UIView animateWithDuration:0.1 animations:^{
                
            [settingTableView setFrame:CGRectMake(stopLocation.x, settingTableView.frame.origin.y, settingTableView.frame.size.width, settingTableView.frame.size.height)];
                
        } completion:^(BOOL finished) {
                
                
        }];
    }
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        
        if(!doPanAnimation)
            return;
        
        CGPoint stopLocation = [(UIPanGestureRecognizer*)sender translationInView:self.view];
        
        if(stopLocation.x >= settingTableView.frame.size.width/2) {
            [UIView animateWithDuration:0.1 animations:^{
                
                [settingTableView setFrame:CGRectMake(settingTableView.frame.size.width-100, settingTableView.frame.origin.y, settingTableView.frame.size.width, settingTableView.frame.size.height)];
                
            } completion:^(BOOL finished) {
                deployed = true;
                
            }];
        } else {
            [UIView animateWithDuration:0.1 animations:^{
                
                [settingTableView setFrame:CGRectMake(0, settingTableView.frame.origin.y, settingTableView.frame.size.width, settingTableView.frame.size.height)];
                
            } completion:^(BOOL finished) {
                deployed = false;
                
            }];
        }
        
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) commitSettings:(id)sender {
    Settings *settings = [Settings get];
    settings.ipServer = serverIP.text;
    
    settings.standalone = [NSNumber numberWithBool:playFromLibrary.on];
    [loadSettingButton setEnabled:[settings.standalone boolValue]];
}

- (IBAction)    loadStandAloneSettings {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load standalone settings"
                                                    message:@"Please make sure that AVRate server is running and waiting for the device and the provided IP is valid."
                                                   delegate:self
                                          cancelButtonTitle:@"Yes, I am sure"
                                          otherButtonTitles:@"I need to check", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 0) {
        [self initNetwork];
        [self loadInterface];
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
	
    NSData *data = [[NSData alloc] initWithData:[@"[ASKPLAYLIST]" dataUsingEncoding:NSASCIIStringEncoding]];
    [ostream write:[data bytes] maxLength:[data length]];
	
	NSString *playlist = @"";
    while(TRUE) {
        int len = [istream read:buffer maxLength:sizeof(buffer)];
        
        NSString *line = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
        
        if(len > 0)
            playlist = [playlist stringByAppendingString:[line substringToIndex:len]];
        
        if(len != sizeof(buffer))
            break;
    }

	// if a playlist was sent, write it!
	if(playlist.length >= 12 && [[playlist substringToIndex:12] isEqual:@"[NOPLAYLIST]"] == FALSE) {
		[self getNewPlaylist:playlist];
	} 
	
	// Ask AVRate to close
	NSString *response = @"[CLOSE]";    
	data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[ostream write:[data bytes] maxLength:[data length]];
	
    
    Settings *settings = [Settings get];    
    settings.xmlViewSettings = xmlData;
    
    [istream close];
    [ostream close];
}

- (void) getNewPlaylist: (NSString*) playlist {
    NSString *nextLine = @"";
    
    // skip message [BEGIN_PLAYLISTS]
    playlist = [playlist substringWithRange:NSMakeRange(20, playlist.length-20)];
    
	BOOL done = false;
	while(!done) {
		if(playlist.length > 17) {
			NSRange pos = [playlist rangeOfString:@"["];
			while(pos.location != NSNotFound) {
				if(playlist.length - pos.location >= 17) {
					if([[playlist substringWithRange:NSMakeRange(pos.location,17)] isEqual:@"[END_ONEPLAYLIST]"]) {
						nextLine = [playlist substringWithRange:NSMakeRange(pos.location+17, playlist.length-pos.location-17)];
						
						NSString *line = [playlist substringWithRange:NSMakeRange(0,pos.location)];

						// There it should write the playlist to a file!
                        [self writeNewPlaylist:line];
                        
					} else if(playlist.length-pos.location >= 18 && [[playlist substringWithRange:NSMakeRange(pos.location,18)] isEqual:@"[END_NEWPLAYLISTS]"]) {
						nextLine = [playlist substringWithRange:NSMakeRange(pos.location+18, playlist.length-pos.location-18)];
						done = true;						
					} else {
                        nextLine = playlist;
                    }
				}
				playlist = nextLine;
				pos = [playlist rangeOfString:@"["];
			}
		}
        
        if (!done) {
            NSString *data = @"";
            while(TRUE) {
                uint8_t buffer[1024];
                int len = [istream read:buffer maxLength:sizeof(buffer)];
                
                NSString *line = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                
                if(len > 0)
                    data = [data stringByAppendingString:[line substringToIndex:len]];
                
                if(len != sizeof(buffer))
                    break;
            }
            playlist = [playlist stringByAppendingString:data];
        }
	}
}

- (void) writeNewPlaylist: (NSString*) playlist {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *newDirectory = [NSString stringWithFormat:@"%@/Playlists", [paths objectAtIndex:0]];
    
    // Check if the directory already exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:newDirectory]) {
        // Directory does not exist so create it
        [[NSFileManager defaultManager] createDirectoryAtPath:newDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    // ----------------------------------------
    // list existing files...
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:newDirectory error:NULL];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/playlist%3.3d.csv",
                          newDirectory, directoryContent.count+1];
    
    // ----------------------------------------
    //save content to the documents directory
    [playlist  writeToFile:fileName
               atomically:NO
               encoding:NSStringEncodingConversionAllowLossy
               error:nil];
    
}

- (IBAction)openMail:(id)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:@"iOSAVRate scores"];
        
        // get all scores...
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *directory = [NSString stringWithFormat:@"%@/Scores", [paths objectAtIndex:0]];
        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
        for (int count = 0; count < (int)[directoryContent count]; count++) {
            NSString *filename = [directoryContent objectAtIndex:count];
            NSString *filePath = [directory stringByAppendingString:@"/"];
            [mailer addAttachmentData:[NSData dataWithContentsOfFile:[filePath stringByAppendingString:filename]]
                             mimeType:@"text/csv"
                             fileName:filename];
        }

        
        
        
        NSString *emailBody = @"Log scores from AVRate";
        [mailer setMessageBody:emailBody isHTML:NO];
        [self presentViewController:mailer animated:YES completion:nil];
     
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support the composer sheet"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(IBAction) deleteScores {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Deleting stored scores"
                                                    message:@"This will delete the previous scores stored on the device. Are you sure to remove all of them?"
                                                   delegate:delScores
                                          cancelButtonTitle:@"Yes, I am sure"
                                          otherButtonTitles:@"No", nil];
    [alert show];
}

-(IBAction) deletePlaylists {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Deleting stored playlists"
                                                    message:@"This will delete the playlists stored on the device. Are you sure to remove all of them?"
                                                   delegate:delPlaylists
                                          cancelButtonTitle:@"Yes, I am sure"
                                          otherButtonTitles:@"No", nil];
    [alert show];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(menuTableView == tableView) {
        return 1;
    } else {
        switch (menuS) {
            case GeneralSettings:
                return 2;
                
            case Standalone:
                return 3;
                
            case SetInterface:
                return mySliders.count+myButtonGroups.count;
                
            default:
                break;
        }
        
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(menuTableView == tableView) {
        return [menuTabData count];
    } else {
        switch (menuS) {
            case GeneralSettings: {
                if(section == 0)
                    return 1;
                else
                    return 2;
            }
                return 3;
                
            case Standalone: {
                switch (section) {
                    case 0:
                        return 2;
                        
                    case 1: {
                        
                        // ----------------------------------------
                        // list existing playlist files...
                        
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                        NSString *newDirectory = [NSString stringWithFormat:@"%@/Playlists", [paths objectAtIndex:0]];
                        
                        // Check if the directory already exists
                        if (![[NSFileManager defaultManager] fileExistsAtPath:newDirectory]) {
                            // Directory does not even exists so nothing to show
                            return 1;
                        }
                        
                        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:newDirectory error:NULL];
                        
                        return directoryContent.count+1;
                        
                    }
                        
                    case 2:
                        return videosOnDeviceLibrary.count;
                        
                    default:
                        break;
                }
            }
                
            case SetInterface: {
                if(section < mySliders.count)
                    return 5;
                else
                    return 2;
            }
                
            default:
                break;
        }
        
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(tableView == settingTableView) {
        
        if(menuS == GeneralSettings) {
            if(section == 0)
                return @"Connection to AVRate";
            else
                return @"Standalone";
        }
        
        if(menuS == Standalone) {
            switch (section) {
                case 0:
                    return @"Manage Scores";
                    
                case 1:
                    return @"Playlists";
                    
                case 2:
                    return @"Training list";
            }
        }
    }
    
    return @"";
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    
    if(menuTableView ==tableView) {
        static NSString *simpleTableIdentifier = @"SettingsMenu";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        cell.textLabel.text = [menuTabData objectAtIndex:indexPath.row];
        return cell;

    } else {
        switch (menuS) {
            case GeneralSettings: {
                if([indexPath section] == 0) {
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GeneralSettingTabServerIP"];
                    
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                      reuseIdentifier:@"GeneralSettingTabServerIP"];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        cell.accessoryView = serverIP;
                        
                    }
                    cell.textLabel.text = @"Server IP";
                    return cell;
                } else {
                    switch( [indexPath row] ) {
                        case 0: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GeneralSettingTabStandAlone"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"GeneralSettingTabStandAlone"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                cell.accessoryView = playFromLibrary;
                            }
                            
                            cell.textLabel.text = @"Standalone mode";
                            return cell;
                            
                        }
                        case 1: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GeneralSettingLoadButton"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"GeneralSettingLoadButton"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                
                                float buttonWidth = 0;
                                if(isPhone) {
                                    buttonWidth = cell.frame.size.width-24;
                                } else {
                                    buttonWidth = 612;
                                }
                                
                                loadSettingButton.frame = CGRectMake(2, 2, buttonWidth, 40);
                                [cell.contentView addSubview:loadSettingButton];
                            }
                            
                            return cell;
                            
                        }
                    }
                }
            }
                
                
                
            case Standalone: {
                if([indexPath section] == 0) {
                    switch( [indexPath row] ) {
                        case 0: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StandaloneSendScores"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"StandaloneSendScores"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                
                                float buttonWidth = 0;
                                if(isPhone) {
                                    buttonWidth = cell.frame.size.width-24;
                                } else {
                                    buttonWidth = 612;
                                }
                                
                                sendScoreButton.frame = CGRectMake(2, 2, buttonWidth, 40);
                                [cell.contentView addSubview:sendScoreButton];
                            }
                            
                            return cell;
                        }
                            
                        case 1: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StandaloneClearScores"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"StandaloneClearScores"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                
                                float buttonWidth = 0;
                                if(isPhone) {
                                    buttonWidth = cell.frame.size.width-24;
                                } else {
                                    buttonWidth = 612;
                                }
                                
                                clearScoresButton.frame = CGRectMake(2, 2, buttonWidth, 40);
                                [cell.contentView addSubview:clearScoresButton];
                            }
                            
                            return cell;
                        }
                    }
                }
                
                if([indexPath section] == 1) {
                    if(indexPath.row == 0) {
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StandaloneClearPlaylist"];
                        
                        if (cell == nil) {
                            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:@"StandaloneClearPlaylist"];
                            cell.selectionStyle = UITableViewCellSelectionStyleNone;
                            
                            float buttonWidth = 0;
                            if(isPhone) {
                                buttonWidth = cell.frame.size.width-24;
                            } else {
                                buttonWidth = 612;
                            }
                            
                            clearPlaylistButton.frame = CGRectMake(2, 2, buttonWidth, 40);
                            [cell.contentView addSubview:clearPlaylistButton];
                        }
                        
                        return cell;
                    }
                    
                    if(indexPath.row > 0) {
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                        NSString *newDirectory = [NSString stringWithFormat:@"%@/Playlists", [paths objectAtIndex:0]];
                        
                        // Check if the directory already exists
                        if (![[NSFileManager defaultManager] fileExistsAtPath:newDirectory]) {
                            // Directory does not exist so create it
                            return 0;
                        }
                        
                        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:newDirectory error:NULL];
                        
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StandalonePlaylists"];
                        
                        if (cell == nil) {
                            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:@"Blank"];
                            cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        }
                        NSString* filename = [directoryContent objectAtIndex:(indexPath.row-1)];
                        cell.textLabel.text = filename;
                        
                        
                        return cell;
                    }
                }
                
                if([indexPath section] == 2) {
                    
                    Settings *setting = [Settings get];
                    bool found = false;
                    for(int i = 0 ; i < setting.trainingList.count ; ++i) {
                        NSNumber *n = [setting.trainingList objectAtIndex:i];
                        if([n integerValue] == indexPath.row)
                            found = true;
                    }
                    
                    
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StandaloneClearScores"];
                        
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:@"Blank"];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    }
                    MPMediaItem* item = [videosOnDeviceLibrary objectAtIndex:(indexPath.row)];
                    cell.textLabel.text = [item valueForProperty:MPMediaItemPropertyTitle];
                    
                    if(found)
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    return cell;
                }
            }
                
            case SetInterface: {
                if([indexPath section] < mySliders.count) {
                    Sliders *slider = [mySliders objectAtIndex:[indexPath section]];
                    switch ([indexPath row]) {
                        case 0: {
                            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:@"SetInterfaceSliderTitle"];
                            cell.selectionStyle = UITableViewCellSelectionStyleNone;
                            UITextField *textfield;
                            if(isPhone)
                                textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 140, 30)];
                            else
                                textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 300, 30)];
                                
                            [textfield setText:slider.title];
                            cell.accessoryView = textfield;
                            cell.textLabel.text = @"Title";
                            return cell;
                        }
                            
                        case 1: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SetInterfaceSliderWithNumber"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"SetInterfaceSliderWithNumber"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                                [switchView setOn:slider.showNumber];
                                cell.accessoryView = switchView;
                            }
                            
                            cell.textLabel.text = @"Show numbers";
                            return cell;
                        }
                            
                        case 2: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SetInterfaceSliderMinNumber"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"SetInterfaceSliderMinNumber"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                UITextField *textfield;
                                if(isPhone)
                                    textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 140, 30)];
                                else
                                    textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 300, 30)];
                                [textfield setText:[NSString stringWithFormat:@"%d", slider.min]];
                                cell.accessoryView = textfield;
                            }
                            
                            cell.textLabel.text = @"Min";
                            return cell;
                        }
                            
                        case 3: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SetInterfaceSliderMaxNumber"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"SetInterfaceSliderMaxNumber"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                UITextField *textfield;
                                if(isPhone)
                                    textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 140, 30)];
                                else
                                    textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 300, 30)];
                                [textfield setText:[NSString stringWithFormat:@"%d", slider.max]];
                                cell.accessoryView = textfield;
                            }
                            
                            cell.textLabel.text = @"Max";
                            return cell;
                        }
                            
                        case 4: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SetInterfaceSliderLabels"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"SetInterfaceSliderLabels"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                UITextField *textfield;
                                if(isPhone)
                                    textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 140, 30)];
                                else
                                    textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 300, 30)];
                                NSString *gLabel = @"";
                                for(int i = 0 ; i < slider.labels.count ; ++i) {
                                    gLabel = [gLabel stringByAppendingString:[slider.labels objectAtIndex:i]];
                                    if(i < slider.labels.count-1)
                                        gLabel = [gLabel stringByAppendingString:@","];
                                }
                                [textfield setText:gLabel];
                                cell.accessoryView = textfield;
                            }
                            
                            cell.textLabel.text = @"labels";
                            return cell;
                        }
                            
                    }
                } else {
                    ButtonGroup *button = [myButtonGroups objectAtIndex:(indexPath.section - mySliders.count)];
                    
                    switch ([indexPath row]) {
                        case 0: {
                            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                           reuseIdentifier:@"SetInterfaceButtonTitle"];
                            cell.selectionStyle = UITableViewCellSelectionStyleNone;
                            UITextField *textfield;
                            if(isPhone)
                                textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 140, 30)];
                            else
                                textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 300, 30)];
                            [textfield setText:button.title];
                            cell.accessoryView = textfield;
                            cell.textLabel.text = @"Title";
                            return cell;
                        }
                            
                        case 1: {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SetInterfaceButtonLabels"];
                            
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                              reuseIdentifier:@"SetInterfaceSliderLabels"];
                                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                UITextField *textfield;
                                if(isPhone)
                                    textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 140, 30)];
                                else
                                    textfield = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 300, 30)];
                                NSString *gLabel = @"";
                                for(int i = 0 ; i < button.labels.count ; ++i) {
                                    gLabel = [gLabel stringByAppendingString:[button.labels objectAtIndex:i]];
                                    if(i < button.labels.count-1)
                                        gLabel = [gLabel stringByAppendingString:@","];
                                }
                                [textfield setText:gLabel];
                                cell.accessoryView = textfield;
                            }
                            
                            cell.textLabel.text = @"labels";
                            return cell;
                        }
                    }
                }
            }
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(menuTableView == tableView) {
        menuS = indexPath.row;
        
        [settingTableView reloadData];
    }
    
    Settings *setting = [Settings get];
    
    if(settingTableView == tableView) {
        if(menuS == Standalone) {
            switch (indexPath.section) {
                    
                case 1: {
                    for (int i = 1 ; i < [settingTableView numberOfRowsInSection:1] ; ++i) {
                        if(i == indexPath.row)
                            continue;
                        
                        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:1];
                        UITableViewCell *cell = [settingTableView cellForRowAtIndexPath:ip];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    
                    
                    UITableViewCell *cell = [settingTableView cellForRowAtIndexPath:indexPath];
                    
                    bool needSelect = false;
                    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        needSelect = false;
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        needSelect = true;
                    }
                    
                    if(needSelect) {
                        setting.selectedPlaylist = [NSNumber numberWithInteger:indexPath.row-1];
                    } else {
                        setting.selectedPlaylist = [NSNumber numberWithInteger:-1];
                    }
                    break;
                }
                    
            
                case 2: {
                    UITableViewCell *cell = [settingTableView cellForRowAtIndexPath:indexPath];
                    
                    bool needSelect = false;
                    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        needSelect = false;
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        needSelect = true;
                    }
                    
                    if(setting.trainingList == NULL) {
                        setting.trainingList = [[NSMutableArray alloc] init];
                    }
                    
                    bool found = false;
                    for(int i = 0 ; i < setting.trainingList.count ; ++i) {
                        NSNumber *n = [setting.trainingList objectAtIndex:i];
                        if([n integerValue] == indexPath.row)
                            found = true;
                        
                        if(!needSelect) {
                            [setting.trainingList removeObjectAtIndex:i];
                            break;
                        }
                    }
                    
                    if(!found && needSelect) {
                        [setting.trainingList addObject:[NSNumber numberWithInt:indexPath.row]];
                    }
                }
            }
        }
    }

}

-(void) parseSettingFile {
    Settings *settings = [Settings get];
    NSData *data=[settings.xmlViewSettings dataUsingEncoding: [NSString defaultCStringEncoding] ];
    NSError *error;
    SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&error];
    
    if (error) {
        return;
    }
    
    SMXMLElement *xmlSettings = document.root;
    
    // Go through every sub-element "video"
    for (SMXMLElement *sl in [xmlSettings childrenNamed:@"slider"]) {

        // min / max / shownumbers
        bool shownumer = [[sl valueWithPath:@"shownumbers"] isEqualToString:@"true"];
        int minV = [[sl valueWithPath:@"min"] intValue];
        int maxV = [[sl valueWithPath:@"max"] intValue];
        
        Sliders *slider = [[Sliders alloc] init];
        slider.labels = [[NSMutableArray alloc] init];
        
        slider.title = [sl valueWithPath:@"name"];
        slider.min = minV;
        slider.max = maxV;
        slider.showNumber = shownumer;

        for(SMXMLElement *lab in [sl childrenNamed:@"label"]) {
            if([lab value] != nil)
                [slider.labels addObject:[lab value]];
            else
                [slider.labels addObject:@""];
        }
        
        [mySliders addObject:slider];
    }
    
    
    for (SMXMLElement *sl in [xmlSettings childrenNamed:@"buttons"]) {

        ButtonGroup *button = [[ButtonGroup alloc] init];
        button.labels = [[NSMutableArray alloc] init];
        
        button.title = [sl valueWithPath:@"name"];

        for(SMXMLElement *lab in [sl childrenNamed:@"label"]) {
            if([lab value] != nil)
                [button.labels addObject:[lab value]];
            else
                [button.labels addObject:@""];
        }
        
        [myButtonGroups addObject:button];
    }
}



@end




@implementation DelegateDeleteScores

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 0) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *directory = [NSString stringWithFormat:@"%@/Scores", [paths objectAtIndex:0]];
        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
        for (int count = 0; count < (int)[directoryContent count]; count++) {
            NSString *filename = [directoryContent objectAtIndex:count];
            NSString *filePath = [directory stringByAppendingString:@"/"];
            
            [[NSFileManager defaultManager] removeItemAtPath:[filePath stringByAppendingString:filename] error:NULL];
        }
    }
}

@end


@implementation DelegateDeletePlaylists

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 0) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *directory = [NSString stringWithFormat:@"%@/Playlists", [paths objectAtIndex:0]];
        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
        for (int count = 0; count < (int)[directoryContent count]; count++) {
            NSString *filename = [directoryContent objectAtIndex:count];
            NSString *filePath = [directory stringByAppendingString:@"/"];
            
            [[NSFileManager defaultManager] removeItemAtPath:[filePath stringByAppendingString:filename] error:NULL];
        }
    }
}

@end




