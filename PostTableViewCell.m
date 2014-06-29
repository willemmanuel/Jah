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
    //Look for a voter object with the devices unique identifier for the post
    PFQuery *voterQuery = [PFQuery queryWithClassName:@"Voter"];
    [voterQuery whereKey:@"postId" equalTo:self.postId];
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
            newCommenter[@"postId"] = self.postId;
            newCommenter[@"voterUniqueId"] = [UIDevice currentDevice].identifierForVendor.UUIDString;
            [newCommenter saveInBackground];
            
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
    }];

}
- (IBAction)downvotePressed:(id)sender {
    PFQuery *voterQuery = [PFQuery queryWithClassName:@"Voter"];
    [voterQuery whereKey:@"postId" equalTo:self.postId];
    [voterQuery whereKey:@"voterUniqueId" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
    [voterQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //If there is no error that means we found a voter so we should do nothing
        if (!error) {
            NSLog(@"You already voted. Your opinion doesn't matter that much");
        }
        else{
            int tempScore = [self.score.text intValue];
            tempScore--;
            self.score.text = [NSString stringWithFormat:@"%d",tempScore];
            PFObject *newCommenter = [PFObject objectWithClassName:@"Voter"];
            newCommenter[@"postId"] = self.postId;
            newCommenter[@"voterUniqueId"] = [UIDevice currentDevice].identifierForVendor.UUIDString;
            [newCommenter saveInBackground];
            
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
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
