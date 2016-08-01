//
//  PlaylistController.h
//  iOSAVRate
//
//  Created by Pierre Lebreton on 08/04/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlaylistController : NSObject {
    
}

- (id)      initWithPlaylist:(int) playListSize :(NSMutableArray *) trainingList;
- (void)    next;
- (int)     getCurrent;
- (void)    generateRandomPlaylist;
- (BOOL)    endOfPlaylist;
- (BOOL)    currentOnePlayable;

@end
