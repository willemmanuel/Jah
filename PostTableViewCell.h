//
//  PostTableViewCell.h
//  PicYak
//
//  Created by Rebecca Mignone on 6/28/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

@class PostTableViewCell;
@protocol PostTableViewCellDelegate <NSObject>
@optional
-(void)upvoteOrDownvoteTapped:(PostTableViewCell*)postTableViewCell;
@end


@interface PostTableViewCell : UITableViewCell
@property (strong, nonatomic) Post *post;
@property (weak, nonatomic) IBOutlet UIImageView *picture;
@property (weak, nonatomic) IBOutlet UIButton *upvoteButton;
@property (weak, nonatomic) IBOutlet UIButton *downvoteButton;
@property (weak, nonatomic) IBOutlet UILabel *score;
@property (weak, nonatomic) IBOutlet UILabel *caption;
@property (nonatomic, assign) id <PostTableViewCellDelegate> delegate;

@end
