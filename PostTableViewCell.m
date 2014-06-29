//
//  PostTableViewCell.m
//  PicYak
//
//  Created by Rebecca Mignone on 6/28/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//
#import <Parse/Parse.h>
#import "PostTableViewCell.h"

@implementation PostTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}
- (IBAction)upvotePressed:(id)sender {
    NSLog(@"%@", self.postId);
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query getObjectInBackgroundWithId:self.postId block:^(PFObject *post, NSError *error) {
        if (!error) {
            // The find succeeded.
            [post incrementKey:@"score"];
            [post saveInBackground];
        } else {
            // Log details of the failure
        }
    }];
}
- (IBAction)downvotePressed:(id)sender {
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query getObjectInBackgroundWithId:self.postId block:^(PFObject *post, NSError *error) {
        if (!error) {
            // #HACKYAF
            [post incrementKey:@"score" byAmount:@-1];
            [post saveInBackground];
        } else {
            // Log details of the failure
        }
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
