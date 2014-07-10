//
//  PYCommentTableViewCell.h
//  PicYak
//
//  Created by William Emmanuel on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comment.h"

@class CommentTableViewCell;
@protocol CommentTableViewCellDelegate <NSObject>
@optional
-(NSString *)upvoteTapped:(CommentTableViewCell*)cell withCommentId:(NSString*)commentId;
-(NSString *)downvoteTapped:(CommentTableViewCell*)cell withCommentId:(NSString*)commentId;
@end

@interface CommentTableViewCell : UITableViewCell
@property (nonatomic, strong) Comment *comment;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIButton *upvoteButton;
@property (weak, nonatomic) IBOutlet UIButton *downvoteButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic, assign) id delegate;

@end
