//
//  PostTableViewCell.m
//  PicYak
//
//  Created by Rebecca Mignone on 6/28/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//


#import <Parse/Parse.h>
#import "PostTableViewCell.h"

@implementation PostTableViewCell {
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

- (void)awakeFromNib
{
    _picture.layer.borderColor = [UIColor colorWithRed:.616 green:.792 blue:.875 alpha:1.0].CGColor;
    _picture.layer.borderWidth = 6;
}
- (IBAction)upvotePressed:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(upvoteTapped:)]) {
        [_delegate upvoteTapped:self];
    }
//    //Look for a voter object with the devices unique identifier for the post
//    PFQuery *voteQuery = [PFQuery queryWithClassName:@"PostVote"];
//    [voteQuery whereKey:@"post" equalTo:self.post.postPFObject];
//    [voteQuery whereKey:@"userDeviceId" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
//    [voteQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
//        if (object) {
//            if ([object[@"upvote"] boolValue] == YES) {
//                [object delete];
//                int tempScore = [self.score.text intValue];
//                tempScore-- ;
//                self.score.text = [NSString stringWithFormat:@"%d",tempScore];
//                
//                PFQuery *query = [PFQuery queryWithClassName:@"Post"];
//                [query getObjectInBackgroundWithId:self.post.postId block:^(PFObject *post, NSError *error) {
//                    if (!error) {
//                        [post incrementKey:@"score" byAmount:@-1];
//                        [post save];
//                        fetching = NO;
//                    } else {
//                        fetching = NO;
//                    }
//                }];
//                
//            } else {
//                // changing from down to upvote
//                object[@"upvote"] = @YES;
//                [object save];
//                // Decrement score
//                PFQuery *query = [PFQuery queryWithClassName:@"Post"];
//                [query getObjectInBackgroundWithId:self.post.postId block:^(PFObject *post, NSError *error) {
//                    if (!error) {
//                        [post incrementKey:@"score" byAmount:@2];
//                        [post save];
//                        fetching = NO;
//                    } else {
//                        fetching = NO;
//                    }
//                }];
//                // Increment label
//                int tempScore = [self.score.text intValue];
//                tempScore += 2;
//                self.score.text = [NSString stringWithFormat:@"%d",tempScore];
//            }
//        }
//        //Otherwise its their first time voting on this post so let them and save their vote
//        else {
//            int tempScore = [self.score.text intValue];
//            tempScore++;
//            self.score.text = [NSString stringWithFormat:@"%d",tempScore];
//            PFObject *newPostVote = [PFObject objectWithClassName:@"PostVote"];
//            newPostVote[@"post"] = self.post.postPFObject;
//            newPostVote[@"userDeviceId"] = [UIDevice currentDevice].identifierForVendor.UUIDString;
//            newPostVote[@"upvote"] = @YES;
//            [newPostVote save];
//            PFQuery *query = [PFQuery queryWithClassName:@"Post"];
//            PFObject *post = [query getObjectWithId:self.post.postId];
//            [post incrementKey:@"score"];
//            [post save];
//            fetching = NO;
//        }
//    }];
}

- (IBAction)downvotePressed:(id)sender {
    if (fetching)
        return;
    fetching = YES;
    //Look for a voter object with the devices unique identifier for the post
    PFQuery *voteQuery = [PFQuery queryWithClassName:@"PostVote"];
    [voteQuery whereKey:@"post" equalTo:self.post.postPFObject];
    [voteQuery whereKey:@"userDeviceId" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
    [voteQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (object) {
            if ([object[@"upvote"] boolValue] == NO) {
                PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                [query getObjectInBackgroundWithId:self.post.postId block:^(PFObject *post, NSError *error) {
                    if (!error) {
                        [post incrementKey:@"score"];
                        [post save];
                        fetching = NO;
                    } else {
                        fetching = NO;
                    }
                }];
                [object delete];
                int tempScore = [self.score.text intValue];
                tempScore++ ;
                self.score.text = [NSString stringWithFormat:@"%d",tempScore];
                fetching = NO;
            } else {
                // changing from down to upvote
                object[@"upvote"] = @NO;
                [object save];
                // Decrement score
                PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                [query getObjectInBackgroundWithId:self.post.postId block:^(PFObject *post, NSError *error) {
                    if (!error) {
                        [post incrementKey:@"score" byAmount:@-2];
                        [post save];
                        fetching = NO;
                    } else {
                        fetching = NO;
                    }
                }];
                // Increment label
                int tempScore = [self.score.text intValue];
                tempScore -= 2;
                self.score.text = [NSString stringWithFormat:@"%d",tempScore];
            }
        }
        //Otherwise its their first time voting on this post so let them and save their vote
        else {
            int tempScore = [self.score.text intValue];
            tempScore--;
            self.score.text = [NSString stringWithFormat:@"%d",tempScore];
            PFObject *newPostVote = [PFObject objectWithClassName:@"PostVote"];
            newPostVote[@"post"] = self.post.postPFObject;
            newPostVote[@"userDeviceId"] = [UIDevice currentDevice].identifierForVendor.UUIDString;
            newPostVote[@"upvote"] = @NO;
            [newPostVote save];
            PFQuery *query = [PFQuery queryWithClassName:@"Post"];
            PFObject *post = [query getObjectWithId:self.post.postId];
            [post incrementKey:@"score" byAmount:@-1];
            [post save];
            fetching = NO;
        }
    }];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
