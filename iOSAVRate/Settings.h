//
//  Settings.h
//  iOSAVRate
//
//  Created by Pierre on 19/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject<NSCoding> {

    NSString    *ipServer;
    NSString    *xmlViewSettings;
    NSNumber    *standalone;
    NSNumber    *selectedPlaylist;
    NSMutableArray *trainingList;
    
}

@property (nonatomic, retain) NSString *ipServer;
@property (nonatomic, retain) NSString *xmlViewSettings;
@property (nonatomic, retain) NSNumber *standalone;
@property (nonatomic, retain) NSNumber *selectedPlaylist;
@property (nonatomic, retain) NSMutableArray *trainingList;

+ (id) get;



@end
