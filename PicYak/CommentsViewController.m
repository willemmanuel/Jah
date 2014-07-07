//
//  CommentsViewController.m
//  PicYak
//
//  Created by Rebecca Mignone on 7/6/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "CommentsViewController.h"
#import "CommentPictureTableViewCell.h"
#import "CommentTableViewCell.h"
#import <Parse/Parse.h>

@interface CommentsViewController (){
    NSMutableArray *comments;
    UITextField *commentBox;
    UIButton *postButton;
    
    CGFloat screenWidth;
    CGFloat screenHeight;
    BOOL keyboardVisible;
    double kOFFSET_FOR_KEYBOARD;
}

@end

@implementation CommentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;

   
    CGFloat yPos = screenHeight - 114.0;
    
    self.commentTextField = [[UIView alloc] initWithFrame:CGRectMake(0, yPos, 320, 50)];
    [self.commentTextField setBackgroundColor:[UIColor colorWithRed:.616 green:.792 blue:.875 alpha:1.0]];
    
    commentBox = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 250, 30)];
    [commentBox setTextColor:[UIColor colorWithRed:28.0/256.0 green:93.0/256.0 blue:130.0/256.0 alpha:1.0]];
    [commentBox setBackgroundColor:[UIColor whiteColor]];
    commentBox.borderStyle = UITextBorderStyleRoundedRect;
    commentBox.font = [UIFont systemFontOfSize:15];
    commentBox.delegate = self;
    [self.commentTextField addSubview:commentBox];
    
    
    postButton = [[UIButton alloc] initWithFrame:CGRectMake(267, 10, 45, 30)];
    [postButton setBackgroundColor:[UIColor colorWithRed:28.0/256.0 green:93.0/256.0 blue:130.0/256.0 alpha:1.0]];
    [postButton setTitle:@"Post" forState:UIControlStateNormal];
    postButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [postButton addTarget:self action:@selector(postButtonPressed:) forControlEvents:UIControlEventTouchDown];
    [self.commentTextField addSubview:postButton];
    
    [self.view addSubview:self.commentTextField];
    
    keyboardVisible = NO;
    kOFFSET_FOR_KEYBOARD = 215.0;
    
    comments = [[NSMutableArray alloc] init];
    [self loadComments];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents: UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:0 context:NULL];
    self.refreshControl = refreshControl;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGRect frame = self.tableView.frame;
    frame.size.height = self.view.frame.size.height-50.0;
    self.tableView.frame = frame;
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    NSLog(@"Began Refreshing");
    [self loadComments];
    [refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Number of rows is the number of time zones in the region for the specified section.
    if(section == 0)
        return 1;
    else return [comments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier;
    if(indexPath.section == 0){
        cellIdentifier = @"PictureCell";
        CommentPictureTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[CommentPictureTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
        [cell.postImage setImage:self.post.picture];
        cell.postImage.layer.borderColor = [UIColor colorWithRed:.616 green:.792 blue:.875 alpha:1.0].CGColor;
        cell.postImage.layer.borderWidth = 6;
        return cell;
    }
    else{
        cellIdentifier = @"CommentCell";
        CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[CommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
        Comment *currentComment = [comments objectAtIndex:(indexPath.row)];
        [cell.commentLabel setText: currentComment.comment];
        cell.scoreLabel.text = [NSString stringWithFormat:@"%d", currentComment.score];
        cell.comment = currentComment;
        cell.dateLabel.text = currentComment.dateString;
        return cell;
    }
}

-(void)loadComments {
    if(!self.refreshControl.isRefreshing){
        NSLog(@"POST ID: %@", self.post.postPFObject.objectId);
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

- (IBAction)postButtonPressed:(id)sender {
    if(keyboardVisible == NO)
        return;
    else if(commentBox.text && commentBox.text.length > 0){
        PFObject *newComment = [PFObject objectWithClassName:@"Comment"];
        [newComment setObject:commentBox.text forKey:@"comment"];
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
        self.post.comments++;
        [self.post.postPFObject incrementKey:@"comments"];
        [self.post.postPFObject saveInBackground];
        self.postComment.text = @"";
        keyboardVisible = NO;
        commentBox.text = @"";
        [self.view endEditing:YES];
        [self setViewMovedUp:NO];
    }
    else return;
}


-(float) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1){
        Comment *currentComment = [comments objectAtIndex:indexPath.row];
        CGSize constraint = CGSizeMake(280.0f, 20000.0f);
        CGSize size = [currentComment.comment sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
        return 28+size.height;
    }
    else return 280.0;
}
- (void) hideKeyboard{
    if(keyboardVisible == YES){
        keyboardVisible = NO;
        [self.commentTextField endEditing:YES];
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardWillShow {
    // Animate the current view out of the way
    NSLog(@"KEYBOARD WILL SHOW");
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardWillHide {
    NSLog(@"Keyboard hiding");
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    NSLog(@"DID begin editing");
    keyboardVisible = YES;
    if  (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
}
- (BOOL)disablesAutomaticKeyboardDismissal {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"Should Return");
    keyboardVisible = NO;
    [self.commentTextField endEditing:YES];
    [self setViewMovedUp:NO];
    //[self.commentTextField resignFirstResponder];
   // if  (self.view.frame.origin.y <= 0)
   // {
   //     [self.commentTextField resignFirstResponder];
   // }
    return YES;
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

@end
