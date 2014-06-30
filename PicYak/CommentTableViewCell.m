//
//  PYCommentTableViewCell.m
//  PicYak
//
//  Created by William Emmanuel on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "CommentTableViewCell.h"
#import <Parse/Parse.h>

@implementation CommentTableViewCell {
    BOOL fetching;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        fetching = NO;
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
    if (fetching)
        return;
    fetching = YES;
    //Look for a voter object with the devices unique identifier for the post
    PFQuery *voteQuery = [PFQuery queryWithClassName:@"CommentVote"];
    [voteQuery whereKey:@"comment" equalTo:self.comment.commentPFObject];
    [voteQuery whereKey:@"userDeviceId" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
    [voteQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (object) {
            if ([object[@"upvote"] boolValue] == YES) {
                [object delete];
                int tempScore = [self.scoreLabel.text intValue];
                tempScore-- ;
                self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
                
                PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                [query getObjectInBackgroundWithId:self.comment.commentId block:^(PFObject *comment, NSError *error) {
                    if (!error) {
                        [comment incrementKey:@"score" byAmount:@-1];
                        [comment save];
                        fetching = NO;
                    } else {
                        fetching = NO;
                    }
                }];
                
            } else {
                // changing from down to upvote
                object[@"upvote"] = @YES;
                [object save];
                // Decrement score
                PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                [query getObjectInBackgroundWithId:self.comment.commentId block:^(PFObject *post, NSError *error) {
                    if (!error) {
                        [post incrementKey:@"score" byAmount:@2];
                        [post save];
                        fetching = NO;
                    } else {
                        fetching = NO;
                    }
                }];
                // Increment label
                int tempScore = [self.scoreLabel.text intValue];
                tempScore += 2;
                self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
            }
        }
        //Otherwise its their first time voting on this post so let them and save their vote
        else {
            int tempScore = [self.scoreLabel.text intValue];
            tempScore++;
            self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
            PFObject *newCommentVote = [PFObject objectWithClassName:@"CommentVote"];
            newCommentVote[@"comment"] = self.comment.commentPFObject;
            newCommentVote[@"userDeviceId"] = [UIDevice currentDevice].identifierForVendor.UUIDString;
            newCommentVote[@"upvote"] = @YES;
            [newCommentVote save];
            PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
            PFObject *post = [query getObjectWithId:self.comment.commentId];
            [post incrementKey:@"score"];
            [post save];
            fetching = NO;
        }
    }];
}

- (IBAction)downvotePressed:(id)sender {
    if (fetching)
        return;
    fetching = YES;
    //Look for a voter object with the devices unique identifier for the post
    PFQuery *voteQuery = [PFQuery queryWithClassName:@"CommentVote"];
    [voteQuery whereKey:@"comment" equalTo:self.comment.commentPFObject];
    [voteQuery whereKey:@"userDeviceId" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
    [voteQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (object) {
            if ([object[@"upvote"] boolValue] == NO) {
                [object delete];
                int tempScore = [self.scoreLabel.text intValue];
                tempScore++ ;
                self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
                
                PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                [query getObjectInBackgroundWithId:self.comment.commentId block:^(PFObject *comment, NSError *error) {
                    if (!error) {
                        [comment incrementKey:@"score"];
                        [comment save];
                        fetching = NO;
                    } else {
                        fetching = NO;
                    }
                }];
                
            } else {
                object[@"upvote"] = @NO;
                [object save];
                // Decrement score
                PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                [query getObjectInBackgroundWithId:self.comment.commentId block:^(PFObject *post, NSError *error) {
                    if (!error) {
                        [post incrementKey:@"score" byAmount:@-2];
                        [post save];
                        fetching = NO;
                    } else {
                        fetching = NO;
                    }
                }];
                // Increment label
                int tempScore = [self.scoreLabel.text intValue];
                tempScore -= 2;
                self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
            }
        }
        //Otherwise its their first time voting on this post so let them and save their vote
        else {
            int tempScore = [self.scoreLabel.text intValue];
            tempScore--;
            self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
            PFObject *newCommentVote = [PFObject objectWithClassName:@"CommentVote"];
            newCommentVote[@"comment"] = self.comment.commentPFObject;
            newCommentVote[@"userDeviceId"] = [UIDevice currentDevice].identifierForVendor.UUIDString;
            newCommentVote[@"upvote"] = @NO;
            [newCommentVote save];
            PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
            PFObject *post = [query getObjectWithId:self.comment.commentId];
            [post incrementKey:@"score" byAmount:@-1];
            [post save];
            fetching = NO;
        }
    }];
}


@end
