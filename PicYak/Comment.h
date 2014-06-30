//
//  Comment.h
//  PicYak
//
//  Created by William Emmanuel on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Comment : NSObject

@property (nonatomic, strong) NSString *commentId;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic) int score;
@property (nonatomic, strong) PFObject *commentPFObject;

- (id) initWithObject: (PFObject *) comment;

@end
