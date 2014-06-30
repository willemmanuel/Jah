//
//  PYCommentsViewController.m
//  PicYak
//
//  Created by William Emmanuel on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "CommentsTableViewController.h"
#import <Parse/Parse.h>
#import "Comment.h"
#import "CommentTableViewCell.h"


@interface CommentsTableViewController () {
    NSMutableArray *comments;
}

@end

@implementation CommentsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    comments = [[NSMutableArray alloc] init];
    [self loadComments];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}


-(void)loadComments {
    if(!self.refreshControl.isRefreshing){
    [comments removeAllObjects];
    PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query orderByAscending:@"createdAt"];
    [query whereKey:@"postId" equalTo:self.post.postPFObject];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Something went wrong with the comments query. We should probably do something here");
        } else {
            for (PFObject *object in objects) {
                NSLog(@"%@", object[@"comment"]);
                Comment *newComment = [[Comment alloc] initWithObject:object];
                [comments addObject:newComment];
                [self.tableView reloadData];
            }
        }
        
    }];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [comments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     static NSString *cellIdentifier = @"CommentCell";
    CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[CommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
        Comment *currentComment = [comments objectAtIndex:indexPath.row];
        [cell.commentLabel setText: currentComment.comment];
        cell.scoreLabel.text = [NSString stringWithFormat:@"%d", currentComment.score];
        cell.comment = currentComment;
    return cell;
}

- (CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *c = [comments objectAtIndex:[indexPath row]] ;
    NSString *text = c.comment;

   // CGSize sizeThatShouldFitTheContent = [_textView sizeThatFits:_textView.frame.size];
   // heightConstraint.constant = sizeThatShouldFitTheContent.height;

    return 10;
}
- (void)refreshTable
{
    [self loadComments];
    [self.refreshControl endRefreshing];
}

- (IBAction)postCommentButtonPressed:(id)sender {
    PFObject *newComment = [PFObject objectWithClassName:@"Comment"];
    [newComment setObject:self.postComment.text forKey:@"comment"];
    [newComment setObject:self.post.postPFObject forKey:@"postId"];
    [newComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [self loadComments];
            [self.tableView reloadData];
        }
        else{
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    [self.view endEditing:YES];
    
}



@end
