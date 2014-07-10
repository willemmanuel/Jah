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

}

- (IBAction)upvotePressed:(id)sender {
    NSString *shouldHighlight;
    if (_delegate && [_delegate respondsToSelector:@selector(upvoteTapped:withCommentId:)]) {
        shouldHighlight = [_delegate upvoteTapped:self withCommentId:self.comment.commentId];
    }
    if ([shouldHighlight isEqualToString:@"0"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Connection Error" message:@"Internet Connection Failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]; [alert show];
        return;
    }
    else if([shouldHighlight isEqualToString:@"1"]){
        [self.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        int tempScore = [self.scoreLabel.text intValue];
        tempScore++;
        self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    else if([shouldHighlight isEqualToString:@"2"]){
        [self.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrow.png"] forState:UIControlStateNormal];
        int tempScore = [self.scoreLabel.text intValue];
        tempScore--;
        self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    else if([shouldHighlight isEqualToString:@"3"]){
        [self.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        [self.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrow.png"] forState:UIControlStateNormal];
        int tempScore = [self.scoreLabel.text intValue];
        tempScore = tempScore + 2;
        self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    
    
}

- (IBAction)downvotePressed:(id)sender {
    NSString *shouldHighlight;
    if (_delegate && [_delegate respondsToSelector:@selector(downvoteTapped:withCommentId:)]) {
        shouldHighlight = [_delegate downvoteTapped:self withCommentId:self.comment.commentId];
    }
    
    if ([shouldHighlight isEqualToString:@"0"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Connection Error" message:@"Internet Connection Failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]; [alert show];
        return;
    }
    else if([shouldHighlight isEqualToString:@"1"]){
        [self.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        int tempScore = [self.scoreLabel.text intValue];
        tempScore--;
        self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    else if([shouldHighlight isEqualToString:@"2"]){
        [self.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrow.png"] forState:UIControlStateNormal];
        int tempScore = [self.scoreLabel.text intValue];
        tempScore++;
        self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    else if([shouldHighlight isEqualToString:@"3"]){
        [self.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        [self.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrow.png"] forState:UIControlStateNormal];
        int tempScore = [self.scoreLabel.text intValue];
        tempScore = tempScore - 2;
        self.scoreLabel.text = [NSString stringWithFormat:@"%d",tempScore];
    }
}

@end
