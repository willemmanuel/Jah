//
//  Post.h
//  PicYak
//
//  Created by Rebecca Mignone on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//
#import "Parse/Parse.h"
#import <Foundation/Foundation.h>

@interface Post : NSObject

@property (nonatomic,strong) NSDate *createdAt;
@property (nonatomic,strong) UIImage *picture;
@property (nonatomic,strong) NSString *caption;
@property (nonatomic,strong) NSString *postId;
@property (nonatomic,strong) CLLocation *location;
@property (nonatomic) int score;


- (id) initWithObject: (PFObject *) post;
- (BOOL)equalToPost:(Post *)aPost;

@end
