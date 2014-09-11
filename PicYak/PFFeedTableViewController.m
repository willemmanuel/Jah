//
//  PFFeedTableViewController.m
//  PicYak
//
//  Created by William Emmanuel on 7/2/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "PFFeedTableViewController.h"
#import <math.h>
#import "CommentsViewController.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <SystemConfiguration/SCNetworkReachability.h>

@interface PFFeedTableViewController () {
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSMutableArray *postVotes;
    UIImageView *emptyFeedImage;
    NSString *uniqueDeviceIdentifier;
}

@end

@implementation PFFeedTableViewController {
    NSMutableArray *_newPosts;
    NSMutableArray *_topPosts;
    NSMutableArray *_hotPosts;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    UIRefreshControl *refresh = [UIRefreshControl new];
    self.refreshControl = refresh;
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    [self.refreshControl addTarget:self action:@selector(refreshPulled) forControlEvents:UIControlEventValueChanged];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _newPostsAreLoading = NO;
    _topPostsAreLoading = NO;
    _hotPostsAreLoading = NO;
    _newPostsAreRefreshing = NO;
    _topPostsAreRefreshing = NO;
    _hotPostsAreRefreshing = NO;
    _processingVote = NO;
    _newPosts = [[NSMutableArray alloc] init];
    _topPosts = [[NSMutableArray alloc] init];
    _hotPosts = [[NSMutableArray alloc] init];
    postVotes = [[NSMutableArray alloc] init];
    uniqueDeviceIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];

    emptyFeedImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 420.0)];
    [emptyFeedImage setImage:[UIImage imageNamed:@"empty.png"]];
    emptyFeedImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:emptyFeedImage];
    emptyFeedImage.hidden = YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)refreshPulled {
    if (_newPostsAreLoading || _topPostsAreLoading || _hotPostsAreLoading)
        return;
    
    [locationManager startUpdatingLocation];
    if(self.segmentedControl.selectedSegmentIndex == 0)
        _newPostsAreRefreshing = YES;
    else if (self.segmentedControl.selectedSegmentIndex == 1)
        _hotPostsAreRefreshing = YES;
    else
        _topPostsAreRefreshing = YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [locationManager startUpdatingLocation];
    
}

- (IBAction)segmentControlValueChanged:(id)sender {
    // lazy load data for a segment choice (write this based on your data
    NSLog(@"");
    if(self.segmentedControl.selectedSegmentIndex == 0)
        [self loadNewPosts];
    else if(self.segmentedControl.selectedSegmentIndex == 1)
        [self loadHotPosts];
    else
        [self loadTopPosts];
    
    // reload data based on the new index
    [self.tableView reloadData];
    
    // reset the scrolling to the top of the table view
    if ([self tableView:self.tableView numberOfRowsInSection:0] > 0) {
        NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:topIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (PostTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[PostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    PFObject *object;
    if(self.segmentedControl.selectedSegmentIndex == 0)
        object = (PFObject *)[_newPosts objectAtIndex:indexPath.row];
    else if(self.segmentedControl.selectedSegmentIndex == 1)
        object = (PFObject *)[_hotPosts objectAtIndex:indexPath.row];
    else
        object = (PFObject *)[_topPosts objectAtIndex:indexPath.row];
    
    Post *currentPost = [[Post alloc] initWithObject:object];
    cell.picture.image = currentPost.picture;
    cell.score.text = [NSString stringWithFormat:@"%d",currentPost.score];
    cell.dateLabel.text = currentPost.createdAtString;
    if (currentPost.caption && [currentPost.caption length] > 0)
        cell.caption.text = currentPost.caption;
    else
        cell.caption.text = @"(No caption)";
    cell.delegate = self;
    cell.post = currentPost;
    if(currentPost.comments == 1) {
        cell.commentsLabel.text = @"1 reply";
    } else {
        cell.commentsLabel.text = [NSString stringWithFormat:@"%d replies", currentPost.comments];
    }
    if([self shouldHighlightUpArrow:cell.post.postId]){
        [cell.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrowHighlighted.png"] forState:UIControlStateNormal];
    }
    else [cell.upvoteButton setImage:[UIImage imageNamed:@"upvoteArrow.png"] forState:UIControlStateNormal];
    
    if([self shouldHighlightDownArrow:cell.post.postId]){
        [cell.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrowHighlighted.png"] forState:UIControlStateNormal];
    }
    else [cell.downvoteButton setImage:[UIImage imageNamed:@"downvoteArrow.png"] forState:UIControlStateNormal];
    
    return cell;
    
}
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.segmentedControl.selectedSegmentIndex == 0)
        return [_newPosts count];
    else if(self.segmentedControl.selectedSegmentIndex == 1)
        return [_hotPosts count];
    else
        return [_topPosts count];
}


- (void)loadNewPosts
{
    if (_newPostsAreLoading)
        return;
    //[_newPosts removeAllObjects];
    PFGeoPoint *southWest = [self findPointWithDistance:5000.0 andBearing:225.0];
    PFGeoPoint *northEast = [self findPointWithDistance:5000.0 andBearing:45.0];
    
    PFQuery *mainQuery = [PFQuery queryWithClassName:@"Post"];
    [mainQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    [mainQuery orderByDescending:@"createdAt"];
    [mainQuery setLimit:6];
    if(_newPostsAreRefreshing){
        [mainQuery setSkip:0];
    }
    else [mainQuery setSkip:_newPosts.count];
    _newPostsAreLoading = YES;
    [mainQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        _newPostsAreLoading = NO;
        if (_newPostsAreRefreshing) {
            [_newPosts removeAllObjects];
            _newPostsAreRefreshing = NO;
        }
        if (!error) {
            for (PFObject *object in objects) {
                [_newPosts addObject:object];
            }
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self.tableView reloadData];
            });
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
        [self.refreshControl endRefreshing];
        _newPostsAreRefreshing = NO;
        if(_newPosts.count == 0)
        {
            emptyFeedImage.hidden = NO;
        }
        else emptyFeedImage.hidden = YES;
    }];
}

- (void)loadTopPosts
{
    if (_topPostsAreLoading)
        return;
    //[_topPosts removeAllObjects];
    PFGeoPoint *southWest = [self findPointWithDistance:5000.0 andBearing:225.0];
    PFGeoPoint *northEast = [self findPointWithDistance:5000.0 andBearing:45.0];
    
    PFQuery *mainQuery = [PFQuery queryWithClassName:@"Post"];
    [mainQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    [mainQuery orderByDescending:@"score"];
    [mainQuery setLimit:6];
    if(_topPostsAreRefreshing){
        [mainQuery setSkip:0];
    }
    else [mainQuery setSkip:_topPosts.count];
    _topPostsAreLoading = YES;
    [mainQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        _topPostsAreLoading = NO;
        if (_topPostsAreRefreshing) {
            [_topPosts removeAllObjects];
            _topPostsAreRefreshing = NO;
        }
        if (!error) {
            for (PFObject *object in objects) {
                [_topPosts addObject:object];
            }
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self.tableView reloadData];
            });
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
        [self.refreshControl endRefreshing];
        _topPostsAreRefreshing = NO;
        if(_topPosts.count == 0)
        {
            emptyFeedImage.hidden = NO;
        }
        else emptyFeedImage.hidden = YES;
    }];
}

// TODO: new hot posts
- (void)loadHotPosts
{
    if (_hotPostsAreLoading)
        return;
    PFGeoPoint *southWest = [self findPointWithDistance:5000.0 andBearing:225.0];
    PFGeoPoint *northEast = [self findPointWithDistance:5000.0 andBearing:45.0];
    
    // Find the date 1.5 days ago
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:-1.5];
    NSDate *twoDaysAgo = [gregorian dateByAddingComponents:components toDate:now options:0];
    
    PFQuery *mainQuery = [PFQuery queryWithClassName:@"Post"];
    [mainQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    [mainQuery orderByDescending:@"score"];
    [mainQuery whereKey:@"createdAt" greaterThan:twoDaysAgo];
    [mainQuery setLimit:6];
    if(_hotPostsAreRefreshing){
        [mainQuery setSkip:0];
    }
    else [mainQuery setSkip:_hotPosts.count];
    _hotPostsAreLoading = YES;
    [mainQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        _hotPostsAreLoading = NO;
        if (_hotPostsAreRefreshing) {
            [_hotPosts removeAllObjects];
            _hotPostsAreRefreshing = NO;
        }
        if (!error) {
            for (PFObject *object in objects) {
                [_hotPosts addObject:object];
            }
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self.tableView reloadData];
            });
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
        [self.refreshControl endRefreshing];
        _hotPostsAreRefreshing = NO;
        if(_hotPosts.count == 0)
        {
            emptyFeedImage.hidden = NO;
        }
        else emptyFeedImage.hidden = YES;
    }];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Post *currentPost;
    if(self.segmentedControl.selectedSegmentIndex == 0){
        if (indexPath.row >= [_newPosts count]) {
            return 0;
        }
         currentPost = [[Post alloc] initWithObject:[_newPosts objectAtIndex:indexPath.row]];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
        if (indexPath.row >= [_hotPosts count]) {
            return 0;
        }
        currentPost = [[Post alloc] initWithObject:[_hotPosts objectAtIndex:indexPath.row]];
    }
    else  {
        if (indexPath.row >= [_topPosts count]) {
            return 0;
        }
        currentPost = [[Post alloc] initWithObject:[_topPosts objectAtIndex:indexPath.row]];
    }
    CGSize constraint = CGSizeMake(280.0f, 20000.0f);
    CGSize size = [currentPost.caption sizeWithFont:[UIFont boldSystemFontOfSize:17.0] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    return 280+30+3+25+size.height;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height - scrollView.contentOffset.y < (self.view.bounds.size.height)) {
        if (self.segmentedControl.selectedSegmentIndex == 0 && !_newPostsAreLoading) {
                [self loadNewPosts];
            
        }
        if (self.segmentedControl.selectedSegmentIndex == 1 && !_hotPostsAreLoading) {
            [self loadHotPosts];
        }
        if (self.segmentedControl.selectedSegmentIndex == 2 && !_topPostsAreLoading) {
            [self loadTopPosts];
        }
    }
}

//Accepts a radius in meters and a bearing (direction) in degrees.
- (PFGeoPoint *) findPointWithDistance:(double) radius andBearing: (double)bearing
{
    double latA = currentLocation.coordinate.latitude * (M_PI/180.0);
    double lonA = currentLocation.coordinate.longitude* (M_PI/180.0);
    double angularDistance = radius/6378137.0; //range divided by the earths radius
    double trueCourse = bearing*(M_PI/180.0);
    
    double lat = asin(
                      sin(latA) * cos(angularDistance) +
                      cos(latA) * sin(angularDistance) * cos(trueCourse));
    
    double dlon = atan2(
                        sin(trueCourse) * sin(angularDistance) * cos(latA),
                        cos(angularDistance) - sin(latA) * sin(lat));
    
    double lon = (fmod((lonA + dlon + M_PI),(2*M_PI))) - M_PI;
    lat = (lat*180/M_PI);
    lon = (lon*180/M_PI);
    
    PFGeoPoint *newPoint = [PFGeoPoint geoPointWithLatitude:lat longitude:lon];
    return newPoint;
}


# pragma mark - targets


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    currentLocation = [locations lastObject];
    [locationManager stopUpdatingLocation];
    if(self.segmentedControl.selectedSegmentIndex == 0)
        [self loadNewPosts];
    else if(self.segmentedControl.selectedSegmentIndex == 1)
        [self loadHotPosts];
    else
        [self loadTopPosts];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showComments"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *currentPost;
        if(self.segmentedControl.selectedSegmentIndex == 0){
            currentPost = [[Post alloc] initWithObject:(PFObject *)[_newPosts objectAtIndex:indexPath.row]];
        }
        else if(self.segmentedControl.selectedSegmentIndex == 1) {
            currentPost = [[Post alloc] initWithObject:(PFObject *)[_hotPosts objectAtIndex:indexPath.row]];
        }
        else  {
            currentPost = [[Post alloc] initWithObject:(PFObject *)[_topPosts objectAtIndex:indexPath.row]];
        }
        CommentsViewController *destViewController = segue.destinationViewController;
        destViewController.post = currentPost;
    }
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
- (BOOL) shouldHighlightUpArrow:(NSString *)postId{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PostVote"];
    postVotes = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSString *predicateString = [NSString stringWithFormat:@"post = '%@'", postId];
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
    postVotes = [[postVotes filteredArrayUsingPredicate:testPredicate] mutableCopy];
    
    for (NSManagedObject *currentPost in postVotes) {
        if([[currentPost valueForKey:@"upvote"]  isEqual: @1]){
            return YES;
        }
        else return NO;
    }
    return NO;
}
- (BOOL) shouldHighlightDownArrow:(NSString *)postId{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PostVote"];
    postVotes = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSString *predicateString = [NSString stringWithFormat:@"post = '%@'", postId];
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
    postVotes = [[postVotes filteredArrayUsingPredicate:testPredicate] mutableCopy];
    
    for (NSManagedObject *currentPost in postVotes) {
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
-  (NSString *) upvoteTapped:(id)sender withPostId:(NSString*)postId{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PostVote"];
    postVotes = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSString *predicateString = [NSString stringWithFormat:@"post = '%@'", postId];
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
    postVotes = [[postVotes filteredArrayUsingPredicate:testPredicate] mutableCopy];
    
    // Look through all the postvotes for one with id == postId
    //Nothing then upvote -> no results return from fetch for postId
    if(!_processingVote){
        _processingVote = YES;
        if([self connectedToNetwork]){
            if (postVotes.count == 0) {
                //create new vote NSManagedObject with postId and upvote =1
                NSManagedObject *newVote = [NSEntityDescription insertNewObjectForEntityForName:@"PostVote" inManagedObjectContext:context];
                [newVote setValue:postId forKey:@"post"];
                [newVote setValue:@YES forKey:@"upvote"];
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                }
                else{
                    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                    [query getObjectInBackgroundWithId:postId block:^(PFObject *post, NSError *error) {
                        [post incrementKey:@"score"];
                        [post saveInBackground];
                    }];
                    _processingVote = NO;
                    return @"1";
                }
            }
            
            else {
                for (NSManagedObject *currentPost in postVotes) {
                    //upvote then upvote -> one result found with upvote = 1
                    if([[currentPost valueForKey:@"upvote"]  isEqual: @1]) {
                        [context deleteObject:currentPost];
                        NSError *error = nil;
                        if (![context save:&error]) {
                            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                        }
                        //decrement the score by 1
                        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                        [query getObjectInBackgroundWithId:postId block:^(PFObject *post, NSError *error) {
                            [post incrementKey:@"score" byAmount:@-1];
                            [post saveInBackground];
                        }];
                        _processingVote = NO;
                        return @"2";
                    }
                    //downvote then upvote -> one result found with upvote = 0
                    //update the upvote field to YES
                    //increment the score by 2
                    else{
                        [currentPost setValue:@YES forKey:@"upvote"];
                        NSError *error = nil;
                        if (![context save:&error]) {
                            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                        }
                        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                        [query getObjectInBackgroundWithId:postId block:^(PFObject *post, NSError *error) {
                            [post incrementKey:@"score" byAmount:@2];
                            [post saveInBackground];
                        }];
                        _processingVote = NO;
                        return @"3";
                    }
                }
            }
        }
        else{
            _processingVote = NO;
            return @"0";
        }
    }
    _processingVote = NO;
    return @"0";
}

//Returns 1 if it should highlight the button and decrement the score by 1
//Returns 2 if it should NOT highlight the button and increment the score by 1
//Returns 3 if it should highlight the button and decrement the score by 2
-  (NSString *) downvoteTapped:(id)sender withPostId:(NSString*)postId{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PostVote"];
    postVotes = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSString *predicateString = [NSString stringWithFormat:@"post = '%@'", postId];
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:predicateString];
    postVotes = [[postVotes filteredArrayUsingPredicate:testPredicate] mutableCopy];
    
    // Look through all the postvotes for one with id == postId
    //Nothing then upvote -> no results return from fetch for postId
    if(!_processingVote){
        _processingVote = YES;
        if([self connectedToNetwork]){
            if (postVotes.count == 0) {
                //create new vote NSManagedObject with postId and upvote =1
                NSManagedObject *newVote = [NSEntityDescription insertNewObjectForEntityForName:@"PostVote" inManagedObjectContext:context];
                [newVote setValue:postId forKey:@"post"];
                [newVote setValue:@NO forKey:@"upvote"];
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                }
                else{
                    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                    [query getObjectInBackgroundWithId:postId block:^(PFObject *post, NSError *error) {
                        [post incrementKey:@"score" byAmount:@-1];
                        [post saveInBackground];
                    }];
                    _processingVote = NO;
                    return @"1";
                }
            }
            
            else {
                for (NSManagedObject *currentPost in postVotes) {
                    //downvote then downvote -> one result found with upvote = 1
                    if([[currentPost valueForKey:@"upvote"]  isEqual: @0]) {
                        //delete this entry from core data
                        [context deleteObject:currentPost];
                        NSError *error = nil;
                        if (![context save:&error]) {
                            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                        }
                        //decrement the score by 1
                        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                        [query getObjectInBackgroundWithId:postId block:^(PFObject *post, NSError *error) {
                            [post incrementKey:@"score"];
                            [post saveInBackground];
                        }];
                        _processingVote = NO;
                        return @"2";
                    }
                    //downvote then upvote -> one result found with upvote = 0
                    //update the upvote field to YES
                    //increment the score by 2
                    else{
                        [currentPost setValue:@NO forKey:@"upvote"];
                        NSError *error = nil;
                        if (![context save:&error]) {
                            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                        }
                        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                        [query getObjectInBackgroundWithId:postId block:^(PFObject *post, NSError *error) {
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

