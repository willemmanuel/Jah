//
//  Comment.m
//  PicYak
//
//  Created by William Emmanuel on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "Comment.h"

@implementation Comment

- (id) initWithObject: (PFObject *) comment{
    self = [super init];
    self.score = [[comment objectForKey:@"score"] intValue];
    self.comment = [comment objectForKey:@"comment"];
    self.commentId = comment.objectId;
    return self;
}

@end
