//
//  PlaylistController.m
//  iOSAVRate
//
//  Created by Pierre Lebreton on 08/04/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import "PlaylistController.h"
#import "Settings.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation PlaylistController {
    int playIndex;
    bool doTraining;
    int playlistSize;
    NSMutableArray *training;
    NSMutableArray *playlist;
    NSMutableArray *trainingPlaylist;
}

- (void) next {
    ++playIndex;
}

-(int) getCurrent {

    if(doTraining) {
        if(playIndex < trainingPlaylist.count) {
            NSNumber *n = [trainingPlaylist objectAtIndex:playIndex];
            return [n intValue];
        } else {
            doTraining = false;
            playIndex = 0;
        }
    }
    
    if(playIndex < playlistSize && playIndex < playlist.count) {
        NSNumber *n = [playlist objectAtIndex:playIndex];
        return [n intValue];
    }
    
    return -1;
}


- (id) initWithPlaylist:(int) playListSize :(NSMutableArray *) trainingList {
    if(self == [super init]) {
        
    }
    
    playlistSize = playListSize;
    training = trainingList;
    playIndex = -1;
    doTraining = true;
    
    Settings *settings = [Settings get];
    
    if([settings.selectedPlaylist integerValue] == -1) {
        [self generateRandomPlaylist];
    } else {
        [self readPlaylistFromFile:[settings.selectedPlaylist integerValue]];
    }
    
    return self;
}

-(void) readPlaylistFromFile: (int) playlistIndex {
    playlist = [[NSMutableArray alloc] init];
    
    // ----------------------------------------
    // read playlist from file
    
    // list existing playlist files...
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *newDirectory = [NSString stringWithFormat:@"%@/Playlists", [paths objectAtIndex:0]];
    
    // Check if the directory already exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:newDirectory]) {
        // Directory does not exist so create it
        [self generateRandomPlaylist];
        return;
    }
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:newDirectory error:NULL];
    if(directoryContent.count <= playlistIndex) {
        [self generateRandomPlaylist];
        return;
    }
    
    // path to file
    NSString *fileName = [newDirectory stringByAppendingString:[@"/" stringByAppendingString:[directoryContent objectAtIndex:playlistIndex]]];
    
    // read file
    NSString *playlistTxt = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:fileName] encoding:NSUTF8StringEncoding];
    
    
    // ----------------------------------------
    // link playlist from file to video library on the device
    NSString *notFound = @"";
    
    // list video on the device
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMovie] forProperty:MPMediaItemPropertyMediaType];
    
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query addFilterPredicate:predicate];
    
    NSArray *videosOnDeviceLibrary = [query items];
    
    // make integer list
    while (true) {
        NSRange pos = [playlistTxt rangeOfString:@"|"];
        if(pos.location == NSNotFound)
            break;
        
        if(pos.location+1 >= playlistTxt.length)
            break;
        
        playlistTxt = [playlistTxt substringFromIndex:pos.location+1];
        NSRange posEnd = [playlistTxt rangeOfString:@"|"];
        
        NSString *videoName = [playlistTxt substringToIndex:posEnd.location];
        
        bool found = false;
        for(int i = 0 ; i < videosOnDeviceLibrary.count ; ++i) {
            MPMediaItem* item = [videosOnDeviceLibrary objectAtIndex:i];
            NSString *vidN = [item valueForProperty:MPMediaItemPropertyTitle];
            
            if([vidN isEqualToString:videoName]) {
                found = true;
                [playlist addObject:[NSNumber numberWithInt:i]];
                break;
            }
        }
        if(!found) {
            notFound = [notFound stringByAppendingString:[ @"\"" stringByAppendingString:[videoName stringByAppendingString:@"\" "]]];
            
        }
    }
    
    if(![notFound isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load playlist - sequence missings"
                                                    message:notFound
                                                   delegate:nil
                                          cancelButtonTitle:@"ok"
                                          otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void) generateRandomPlaylist {
    playlist = [[NSMutableArray alloc] init];
    
    for (int k = 0; k < playlistSize; k++) {
        [playlist addObject:[NSNumber numberWithInt:k]];
    }
    
    
    
    for (int k = playlistSize-1; k > 0; k--) {
        int j = arc4random() % k;
        id temp = [playlist objectAtIndex:j];
        if(j == k)
            continue;
        
        [playlist replaceObjectAtIndex:j withObject:[playlist objectAtIndex:k]];
        [playlist replaceObjectAtIndex:k withObject:temp];
    }




    trainingPlaylist = [[NSMutableArray alloc] init];

    for (int k = 0; k < training.count; k++) {
        [trainingPlaylist addObject:[NSNumber numberWithInt:k]];
    }



    for (int k = trainingPlaylist.count-1; k > 0; k--) {
        int j = arc4random() % k;
        id temp = [trainingPlaylist objectAtIndex:j];
        if(j == k)
            continue;
    
        [trainingPlaylist replaceObjectAtIndex:j withObject:[trainingPlaylist objectAtIndex:k]];
        [trainingPlaylist replaceObjectAtIndex:k withObject:temp];
    }
}

- (BOOL) currentOnePlayable {
    return (playIndex < playlistSize) && (playIndex < playlist.count);
}

- (BOOL) endOfPlaylist {
    return ((playIndex+1) >= playlistSize) || ((playIndex+1) >= playlist.count);
}

@end

