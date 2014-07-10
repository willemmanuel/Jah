//
//  CommentsViewController.m
//  PicYak
//
//  Created by Thomas Mignone on 7/6/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "CommentsViewController.h"
#import "CommentPictureTableViewCell.h"
#import "CommentTableViewCell.h"
#import <Parse/Parse.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <SystemConfiguration/SCNetworkReachability.h>

@interface CommentsViewController (){
    NSMutableArray *comments;
    NSMutableArray *commentVotes;
    UITextField *commentBox;
    UIButton *postButton;
    CGFloat screenWidth;
    CGFloat screenHeight;
    double kOFFSET_FOR_KEYBOARD;
    UIImageView *emptyCommentsImage;
    BOOL keyboardVisible;
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
    commentVotes = [[NSMutableArray alloc] init];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;
    _isLoading = NO;
    _isRefreshing = NO;
    _processingVote = NO;
    
    CGFloat yPos = screenHeight - 114.0;
    self.commentTextField = [[UIView alloc] initWithFrame:CGRectMake(0, yPos, 320, 50)];
    //[self.commentTextField setBackgroundColor:[UIColor colorWithRed:88.0/256.0 green:202.0/256.0 blue:224.0/256.0 alpha:1.0]];
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
    postButton.layer.cornerRadius = 5;
    postButton.clipsToBounds = YES;
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
   // self.tableView.delegate = self;
    //self.tableView.dataSource = self;
    
    emptyCommentsImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 325.0, self.view.frame.size.width, 40.0)];
    [emptyCommentsImage setImage:[UIImage imageNamed:@"noComments.png"]];
    emptyCommentsImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.tableView addSubview:emptyCommentsImage];
    emptyCommentsImage.hidden = YES;
    self.refreshControl = refreshControl;
}
- (void) dealloc{
    [self.tableView removeObserver:self forKeyPath:@"contentSize"];
}
- (IBAction)reportButtonPressed:(id)sender {
    if (!keyboardVisible) {
        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Flag as Inappropriate" otherButtonTitles:nil];
        popup.tag = 1;
        [popup showInView:[UIApplication sharedApplication].keyWindow];
    }
    
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (popup.tag) {
            
        case 1: {
            switch (buttonIndex) {
                case 0:{
                    
                    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                    [query getObjectInBackgroundWithId:self.post.postId block:^(PFObject *currentPost, NSError *error) {
                        if(!error){
                            
                            int reportCount = [[currentPost objectForKey:@"reports"] intValue];
                           
                            NSManagedObjectContext *context = [self managedObjectContext];
                            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Report"];
                            NSMutableArray *reports = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
                            NSString *predicateString = [NSString stringWithFormat:@"post = '%@'", self.post.postId];
                            NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
                            reports = [[reports filteredArrayUsingPredicate:testPredicate] mutableCopy];
                            if(reports.count == 0){
                                if (reportCount == 2) {
                                    NSManagedObject *newReport = [NSEntityDescription insertNewObjectForEntityForName:@"Report" inManagedObjectContext:context];
                                    [newReport setValue:self.post.postId forKey:@"post"];
                                    NSError *error = nil;
                                    if (![context save:&error]) {
                                        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                                    }
                                    [currentPost deleteInBackground];
                                }
                                else{
                                    NSManagedObject *newReport = [NSEntityDescription insertNewObjectForEntityForName:@"Report" inManagedObjectContext:context];
                                    [newReport setValue:self.post.postId forKey:@"post"];
                                    NSError *error = nil;
                                    if (![context save:&error]) {
                                        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                                    }
                                    [currentPost incrementKey:@"reports"];
                                    [currentPost saveInBackground];
                                }
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thanks!" message:@"Your report has been submitted" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                                [alert show];
                            }
                            else{
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoops" message:@"You may only report a post once. We appreciate your help in making Jah a better community." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                                [alert show];
                            }
                        }
                    }];
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGRect frame = self.tableView.frame;
    frame.size.height = self.view.frame.size.height-50.0;
    self.tableView.frame = frame;
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [self loadComments];
    
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
        cell.delegate = self;
        cell.dateLabel.text = currentComment.dateString;
        if([self shouldHighlightUpArrow:cell.comment.commentId]){
            [cell.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        }
        else [cell.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrow.png"] forState:UIControlStateNormal];
        
        if([self shouldHighlightDownArrow:cell.comment.commentId]){
            [cell.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrowHighlighted.png"] forState:UIControlStateNormal];
        }
        else [cell.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrow.png"] forState:UIControlStateNormal];
        return cell;
    }
}

-(void)loadComments {
    //if(!self.refreshControl.isRefreshing){
    if (_isLoading) {
        return;
    }
    
        PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
        //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
        [query orderByAscending:@"createdAt"];
    
        [query whereKey:@"postId" equalTo:self.post.postPFObject];
        _isLoading = YES;
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            _isLoading = NO;
            if (error) {
                NSLog(@"Something went wrong with the comments query. We should probably do something here");
            }
            else {
                [comments removeAllObjects];
                for (PFObject *object in objects) {
                    Comment *newComment = [[Comment alloc] initWithObject:object];
                    [comments addObject:newComment];
                    //[self.tableView reloadData];
                }
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self.tableView reloadData];
                });
            }
            [self.refreshControl endRefreshing];
            if(comments.count == 0){
                NSLog(@"Showing empty comments view");
                emptyCommentsImage.hidden = NO;
            }
            else emptyCommentsImage.hidden = YES;
        }];
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


-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1){
        Comment *currentComment = [comments objectAtIndex:indexPath.row];
        CGSize constraint = CGSizeMake(280.0f, 20000.0f);
        CGSize size = [currentComment.comment sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
        return 31.0+size.height;
    }
    else return 325.0;
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
    keyboardVisible = NO;
    [self.commentTextField endEditing:YES];
    [self setViewMovedUp:NO];
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

# pragma mark - upvote/downvote delegate methods

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}
- (BOOL) shouldHighlightUpArrow:(NSString *)commentId{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"CommentVote"];
    commentVotes = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSString *predicateString = [NSString stringWithFormat:@"comment = '%@'", commentId];
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
    commentVotes = [[commentVotes filteredArrayUsingPredicate:testPredicate] mutableCopy];
    
    for (NSManagedObject *currentPost in commentVotes) {
        if([[currentPost valueForKey:@"upvote"]  isEqual: @1]){
            return YES;
        }
        else return NO;
    }
    return NO;
}
- (BOOL) shouldHighlightDownArrow:(NSString *)commentId{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"CommentVote"];
    commentVotes = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSString *predicateString = [NSString stringWithFormat:@"comment = '%@'", commentId];
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
    commentVotes = [[commentVotes filteredArrayUsingPredicate:testPredicate] mutableCopy];
    
    for (NSManagedObject *currentPost in commentVotes) {
        if([[currentPost valueForKey:@"upvote"]  isEqual: @0]){
            return YES;
        }
        else return NO;
    }
    return NO;
}
//Returns 1 if it should highlight the button and increment the score by 1
//Returns 2 if it should NOT highlight the button and decrement the score by 1
//Returns 3 if it should highlight the button and increment the score by 2
-  (NSString *) upvoteTapped:(id)sender withCommentId:(NSString *)commentId{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"CommentVote"];
    commentVotes = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSString *predicateString = [NSString stringWithFormat:@"comment = '%@'", commentId];
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
    commentVotes = [[commentVotes filteredArrayUsingPredicate:testPredicate] mutableCopy];

    _processingVote = YES;
    if([self connectedToNetwork]){
        if (commentVotes.count == 0) {
            NSManagedObject *newVote = [NSEntityDescription insertNewObjectForEntityForName:@"CommentVote" inManagedObjectContext:context];
            [newVote setValue:commentId forKey:@"comment"];
            [newVote setValue:@YES forKey:@"upvote"];
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
            }
            else{
                PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                [query getObjectInBackgroundWithId:commentId block:^(PFObject *post, NSError *error) {
                    [post incrementKey:@"score"];
                    [post saveInBackground];
                }];
                _processingVote = NO;
                return @"1";
            }
        }
        
        else {
            for (NSManagedObject *currentPost in commentVotes) {
                if([[currentPost valueForKey:@"upvote"]  isEqual: @1]) {
                    [context deleteObject:currentPost];
                    NSError *error = nil;
                    if (![context save:&error]) {
                        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                    }
                    PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                    [query getObjectInBackgroundWithId:commentId block:^(PFObject *post, NSError *error) {
                        [post incrementKey:@"score" byAmount:@-1];
                        [post saveInBackground];
                    }];
                    _processingVote = NO;
                    return @"2";
                }
                else{
                    [currentPost setValue:@YES forKey:@"upvote"];
                    NSError *error = nil;
                    if (![context save:&error]) {
                        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                    }
                    PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                    [query getObjectInBackgroundWithId:commentId block:^(PFObject *post, NSError *error) {
                        [post incrementKey:@"score" byAmount:@2];
                        [post saveInBackground];
                    }];
                    _processingVote = NO;
                    return @"3";
                }
            }
        }
    }
    else {
        _processingVote = NO;
        return @"0";
    }
    _processingVote = NO;
    return @"0";
}

//Returns 1 if it should highlight the button and decrement the score by 1
//Returns 2 if it should NOT highlight the button and increment the score by 1
//Returns 3 if it should highlight the button and decrement the score by 2
-  (NSString *) downvoteTapped:(id)sender withCommentId:(NSString *)commentId{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"CommentVote"];
    commentVotes = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSString *predicateString = [NSString stringWithFormat:@"comment = '%@'", commentId];
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
    commentVotes = [[commentVotes filteredArrayUsingPredicate:testPredicate] mutableCopy];
    
    _processingVote = YES;
    if([self connectedToNetwork]){
        if (commentVotes.count == 0) {
            NSManagedObject *newVote = [NSEntityDescription insertNewObjectForEntityForName:@"CommentVote" inManagedObjectContext:context];
            [newVote setValue:commentId forKey:@"comment"];
            [newVote setValue:@NO forKey:@"upvote"];
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
            }
            else{
                PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                [query getObjectInBackgroundWithId:commentId block:^(PFObject *post, NSError *error) {
                    [post incrementKey:@"score" byAmount:@-1];
                    [post saveInBackground];
                }];
                _processingVote = NO;
                return @"1";
            }
        }
        
        else {
            for (NSManagedObject *currentPost in commentVotes) {
                if([[currentPost valueForKey:@"upvote"]  isEqual: @0]) {
                    [context deleteObject:currentPost];
                    NSError *error = nil;
                    if (![context save:&error]) {
                        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                    }
                    PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                    [query getObjectInBackgroundWithId:commentId block:^(PFObject *post, NSError *error) {
                        [post incrementKey:@"score"];
                        [post saveInBackground];
                    }];
                    _processingVote = NO;
                    return @"2";
                }
                else{
                    [currentPost setValue:@NO forKey:@"upvote"];
                    NSError *error = nil;
                    if (![context save:&error]) {
                        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                    }
                    PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
                    [query getObjectInBackgroundWithId:commentId block:^(PFObject *post, NSError *error) {
                        [post incrementKey:@"score" byAmount:@-2];
                        [post saveInBackground];
                    }];
                    _processingVote = NO;
                    return @"3";
                }
            }
        }
    }
    else {
        _processingVote = NO;
        return @"0";
    }
    _processingVote = NO;
    return @"0";
}

- (BOOL) connectedToNetwork
{
	// Create zero addy
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
    
	// Recover reachability flags
	SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	SCNetworkReachabilityFlags flags;
    
	BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
	CFRelease(defaultRouteReachability);
    
	if (!didRetrieveFlags)
	{
		return NO;
	}
    
	BOOL isReachable = flags & kSCNetworkFlagsReachable;
	BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	return (isReachable && !needsConnection) ? YES : NO;
}

@end
