//
//  PYCommentsViewController.h
//  PicYak
//
//  Created by William Emmanuel on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

@interface CommentsTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UITextField *postComment;
@property (weak, nonatomic) IBOutlet UIButton *postCommentButton;
@property (strong, nonatomic) Post* post;

@end
