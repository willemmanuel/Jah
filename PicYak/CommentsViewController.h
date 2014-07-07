//
//  CommentsViewController.h
//  PicYak
//
//  Created by Rebecca Mignone on 7/6/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

@interface CommentsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *postComment;
@property (weak, nonatomic) IBOutlet UIButton *postCommentButton;
@property (strong, nonatomic) Post* post;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property UIView *commentTextField;

@end
