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
    self.commentPFObject = comment;
    self.createdAt = comment.createdAt;
    self.dateString = [self dateDiff:self.createdAt];
    return self;
}

-(NSString *)dateDiff:(NSDate *)convertedDate {
    NSDate *todayDate = [NSDate date];
    double ti = [convertedDate timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    if(ti < 1) {
    	return @"1m";
    } else 	if (ti < 60) {
    	return @"1m";
    } else if (ti < 3600) {
    	int diff = round(ti / 60);
    	return [NSString stringWithFormat:@"%dm", diff];
    } else if (ti < 86400) {
    	int diff = round(ti / 60 / 60);
    	return[NSString stringWithFormat:@"%dh", diff];
    } else if (ti < 2629743) {
    	int diff = round(ti / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%dd", diff];
    } else {
    	return @"never";
    }
}
@end
