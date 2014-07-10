//
//  CommentsViewController.h
//  PicYak
//
//  Created by Thomas Mignone on 7/6/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "CommentTableViewCell.h"
@interface CommentsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate, CommentTableViewCellDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UITextField *postComment;
@property (weak, nonatomic) IBOutlet UIButton *postCommentButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *reportButton;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) Post* post;
@property UIView *commentTextField;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL isRefreshing;
@property (nonatomic) BOOL processingVote;

@end
