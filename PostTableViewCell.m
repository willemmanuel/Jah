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
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}
- (IBAction)upvotePressed:(id)sender {
    NSString *shouldHighlight;
    if (_delegate && [_delegate respondsToSelector:@selector(upvoteTapped:withPostId:)]) {
        shouldHighlight = [_delegate upvoteTapped:self withPostId:self.post.postId];
    }
    if ([shouldHighlight isEqualToString:@"0"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Connection Error" message:@"Internet Connection Failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]; [alert show];
        return;
    }
    else if([shouldHighlight isEqualToString:@"1"]){
        [self.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        int tempScore = [self.score.text intValue];
        tempScore++;
        self.score.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    else if([shouldHighlight isEqualToString:@"2"]){
        [self.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrow.png"] forState:UIControlStateNormal];
        int tempScore = [self.score.text intValue];
        tempScore--;
        self.score.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    else if([shouldHighlight isEqualToString:@"3"]){
        [self.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        [self.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrow.png"] forState:UIControlStateNormal];
        int tempScore = [self.score.text intValue];
        tempScore = tempScore + 2;
        self.score.text = [NSString stringWithFormat:@"%d",tempScore];
    }


}

- (IBAction)downvotePressed:(id)sender {
    NSString *shouldHighlight;
    if (_delegate && [_delegate respondsToSelector:@selector(downvoteTapped:withPostId:)]) {
        shouldHighlight = [_delegate downvoteTapped:self withPostId:self.post.postId];
    }
    if ([shouldHighlight isEqualToString:@"0"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Connection Error" message:@"Internet Connection Failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]; [alert show];
        return;
    }
    else if([shouldHighlight isEqualToString:@"1"]){
        [self.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        int tempScore = [self.score.text intValue];
        tempScore--;
        self.score.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    else if([shouldHighlight isEqualToString:@"2"]){
        [self.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrow.png"] forState:UIControlStateNormal];
        int tempScore = [self.score.text intValue];
        tempScore++;
        self.score.text = [NSString stringWithFormat:@"%d",tempScore];
    }
    else if([shouldHighlight isEqualToString:@"3"]){
        [self.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        [self.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrow.png"] forState:UIControlStateNormal];
        int tempScore = [self.score.text intValue];
        tempScore = tempScore - 2;
        self.score.text = [NSString stringWithFormat:@"%d",tempScore];
    }

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
