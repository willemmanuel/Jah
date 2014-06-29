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
    int tempScore = [self.score.text intValue];
    tempScore++;
    self.score.text = [NSString stringWithFormat:@"%d",tempScore];
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query getObjectInBackgroundWithId:self.postId block:^(PFObject *post, NSError *error) {
        if (!error) {
            // The find succeeded.
            [post incrementKey:@"score"];
            [post saveInBackground];
            /*if(_delegate && [_delegate respondsToSelector:@selector(upvoteOrDownvoteTapped:)]) {
                [_delegate upvoteOrDownvoteTapped:self];
            }*/
        } else {
            // Log details of the failure
        }
    }];
}
- (IBAction)downvotePressed:(id)sender {
    int tempScore = [self.score.text intValue];
    tempScore--;
    self.score.text = [NSString stringWithFormat:@"%d",tempScore];
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query getObjectInBackgroundWithId:self.postId block:^(PFObject *post, NSError *error) {
        if (!error) {
            // #HACKYAF
            [post incrementKey:@"score" byAmount:@-1];
            [post saveInBackground];
            /*if(_delegate && [_delegate respondsToSelector:@selector(upvoteOrDownvoteTapped:)]) {
                [_delegate upvoteOrDownvoteTapped:self];
            }*/
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
