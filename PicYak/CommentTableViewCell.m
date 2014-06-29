//
//  PYCommentTableViewCell.m
//  PicYak
//
//  Created by William Emmanuel on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "CommentTableViewCell.h"
#import <Parse/Parse.h>

@implementation CommentTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}
- (void)awakeFromNib
{
    // Initialization code
}
- (IBAction)upvotePressed:(id)sender {
    //Look for a voter object with the devices unique identifier for the post
    PFQuery *voterQuery = [PFQuery queryWithClassName:@"Voter"];
    [voterQuery whereKey:@"id" equalTo:self.commentId];
    [voterQuery whereKey:@"voterUniqueId" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
    [voterQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //If there is no error that means we found a voter so we should do nothing
        if (!error) {
            NSLog(@"You already voted. Your opinion doesn't matter that much");
        }
        //Otherwise its their first time voting on this post so let them and save their vote
        else {
            int tempScore = [self.score.text intValue];
            tempScore++;
            self.score.text = [NSString stringWithFormat:@"%d",tempScore];
            PFObject *newCommenter = [PFObject objectWithClassName:@"Voter"];
            newCommenter[@"id"] = self.commentId;
            newCommenter[@"voterUniqueId"] = [UIDevice currentDevice].identifierForVendor.UUIDString;
            [newCommenter saveInBackground];
            
            PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
            [query getObjectInBackgroundWithId:self.commentId block:^(PFObject *comment, NSError *error) {
                if (!error) {
                    // The find succeeded.
                    [comment incrementKey:@"score"];
                    [comment saveInBackground];
                    /*if(_delegate && [_delegate respondsToSelector:@selector(upvoteOrDownvoteTapped:)]) {
                     [_delegate upvoteOrDownvoteTapped:self];
                     }*/
                } else {
                    // Log details of the failure
                }
            }];
        }
    }];

}

- (IBAction)downvotePressed:(id)sender {
    //Look for a voter object with the devices unique identifier for the post
    PFQuery *voterQuery = [PFQuery queryWithClassName:@"Voter"];
    [voterQuery whereKey:@"id" equalTo:self.commentId];
    [voterQuery whereKey:@"voterUniqueId" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
    [voterQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //If there is no error that means we found a voter so we should do nothing
        if (!error) {
            NSLog(@"You already voted. Your opinion doesn't matter that much");
        }
        //Otherwise its their first time voting on this post so let them and save their vote
        else {
            int tempScore = [self.score.text intValue];
            tempScore++;
            self.score.text = [NSString stringWithFormat:@"%d",tempScore];
            PFObject *newCommenter = [PFObject objectWithClassName:@"Voter"];
            newCommenter[@"id"] = self.commentId;
            newCommenter[@"voterUniqueId"] = [UIDevice currentDevice].identifierForVendor.UUIDString;
            [newCommenter saveInBackground];
            
            PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
            [query getObjectInBackgroundWithId:self.commentId block:^(PFObject *comment, NSError *error) {
                if (!error) {
                    // The find succeeded.
                    [comment incrementKey:@"score" byAmount:@-1];
                    [comment saveInBackground];
                    /*if(_delegate && [_delegate respondsToSelector:@selector(upvoteOrDownvoteTapped:)]) {
                     [_delegate upvoteOrDownvoteTapped:self];
                     }*/
                } else {
                    // Log details of the failure
                }
            }];
        }
    }];
}

@end
