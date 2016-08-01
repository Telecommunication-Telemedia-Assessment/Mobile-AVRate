//
//  SettingsViewController.h
//  iOSAVRate
//
//  Created by Pierre on 19/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import <MessageUI/MessageUI.h>


@interface DelegateDeleteScores : UIViewController<UIAlertViewDelegate>

@end

@interface DelegateDeletePlaylists : UIViewController<UIAlertViewDelegate>

@end

@interface SettingsViewController : UIViewController<NSStreamDelegate,UIAlertViewDelegate, MFMailComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource> {

    enum MenuSelected {
        GeneralSettings,
        Standalone,
        SetInterface
    };

    // -----------------------------------------
    // read settings
    UITextField    *serverIP;
    UISwitch       *playFromLibrary;
    UIButton       *loadSettingButton;
    UIButton       *sendScoreButton;
    UIButton       *clearScoresButton;
    UIButton       *clearPlaylistButton;
    
    IBOutlet UITableView    *menuTableView;
    IBOutlet UITableView    *settingTableView;
    NSArray *menuTabData;
    NSArray *videosOnDeviceLibrary;
    enum MenuSelected menuS;
    
    NSMutableArray *mySliders;
    NSMutableArray *myButtonGroups;
    
    bool doPanAnimation;
    bool deployed;
    
    DelegateDeleteScores    *delScores;
    DelegateDeletePlaylists *delPlaylists;
    // ----------------------------------------
    // communication with server.
    NSInputStream *istream;
    NSOutputStream *ostream;
    
}

- (IBAction)    loadStandAloneSettings;
- (IBAction)    openMail:(id)sender;
- (IBAction)    deleteScores;



@end


