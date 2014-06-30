//
//  Post.m
//  PicYak
//
//  Created by Rebecca Mignone on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>
#import "Post.h"

@implementation Post

- (id) initWithObject: (PFObject *) post{
    self = [super init];
    self.caption = post[@"caption"];
    self.score = [[post objectForKey:@"score"] intValue];
    self.postId = post.objectId;
    self.createdAt = post.createdAt;
    self.postPFObject = post;
    
    PFGeoPoint *location = [post objectForKey:@"location"];
    self.location = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    PFFile *imageFile = [post objectForKey:@"picture"];
    //[imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
    NSData *data = [imageFile getData];
    //    if (!error) {
            self.picture = [UIImage imageWithData:data];
      //  }
    //}];
    return self;
}

- (BOOL)equalToPost:(Post *)aPost {
	if (aPost == nil) {
		return NO;
	}
    if(aPost.score != self.score){
        return NO;
    }
	if (aPost.postId && self.postId) {
		// We have a PFObject inside the PAWPost, use that instead.
		if ([aPost.postId compare:self.postId] != NSOrderedSame) {
			return NO;
		}
		return YES;
	}

    return NO;
}

@end
