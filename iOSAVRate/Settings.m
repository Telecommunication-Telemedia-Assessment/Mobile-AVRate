//
//  Settings.m
//  iOSAVRate
//
//  Created by Pierre on 19/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import "Settings.h"

@implementation Settings

@synthesize ipServer;
@synthesize xmlViewSettings;
@synthesize standalone;
@synthesize trainingList;
@synthesize selectedPlaylist;

#define kSERVER_IP           @"SERVERIP"
#define kSTANDALONE          @"STANDALONE"
#define kXMLSETTTINGS        @"XMLSETTINGS"
#define kTRAININGLIST        @"TRAININGLIST"
#define kSELECTEDPLAYLIST    @"SELECTEDPLAYLIST"
#define kDataFile            @"data.plist"


+ (id) get {
    static Settings *shared_settings = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        shared_settings = [[self alloc] init];
    });
    
    return shared_settings;
    
}

- (id) init {
    if(self == [super init]) {
        ipServer = @"localhost";
        trainingList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id) initWithServerIP:(NSString *) ip {
    if(self == [super init]) {
        
    }
    
    ipServer = ip;
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:ipServer forKey:kSERVER_IP];
    [encoder encodeObject:xmlViewSettings forKey:kXMLSETTTINGS];
    [encoder encodeObject:standalone forKey:kSTANDALONE];
    [encoder encodeObject:trainingList forKey:kTRAININGLIST];
    [encoder encodeObject:selectedPlaylist forKey:kSELECTEDPLAYLIST];
}

- (id)initWithCoder:(NSCoder *)decoder {
    NSString *serverIP = [decoder decodeObjectForKey:kSERVER_IP];
    NSString *xmlData = [decoder decodeObjectForKey:kXMLSETTTINGS];
    NSNumber *number = [decoder decodeObjectForKey:kSTANDALONE];
    NSMutableArray *training = [decoder decodeObjectForKey:kTRAININGLIST];
    NSNumber *selPlaylist = [decoder decodeObjectForKey:kSELECTEDPLAYLIST];
    
    if((self = [super init])) {
        self.ipServer = serverIP;
        self.xmlViewSettings = xmlData;
        standalone = number;
        trainingList = training;
        selectedPlaylist = selPlaylist;
    }

    return self;
}



@end
