//
//  PFFeedTableViewController.m
//  PicYak
//
//  Created by William Emmanuel on 7/2/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "PFFeedTableViewController.h"
#import "CommentsTableViewController.h"

@interface PFFeedTableViewController () {
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSString *uniqueDeviceIdentifier;
}

@end

@implementation PFFeedTableViewController {
    NSMutableArray *_objects;
    NSMutableArray *_objectIDs;
    NSDate *_oldestPost;
    BOOL _isLoading;
    BOOL _isRefreshing;
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
    _isLoading = NO;
    _isRefreshing = NO;
    _objects = [[NSMutableArray alloc] init];
    _objectIDs = [[NSMutableArray alloc] init];
    uniqueDeviceIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    UIBarButtonItem *takePicture = [[UIBarButtonItem alloc]initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(newPost:)];
    self.navigationItem.rightBarButtonItem = takePicture;
    [self loadObjects];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)refreshPulled {
    if (_isLoading)
        return;
    _isRefreshing = YES;
    [self loadObjects];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [locationManager startUpdatingLocation];
}

- (PostTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[PostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    PFObject *object = (PFObject *)[_objects objectAtIndex:indexPath.row];
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
    return cell;
}
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_objects count];
}
- (void)loadObjects
{
    if (_isLoading)
        return;
    PFQuery *mainQuery = [PFQuery queryWithClassName:@"Post"];
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
	[mainQuery whereKey:@"location" nearGeoPoint:point withinKilometers:5.28];
    [mainQuery orderByDescending:@"createdAt"];
    if ([_objectIDs count] > 0 && !_isRefreshing) {
        [mainQuery whereKey:@"objectId" notContainedIn:_objectIDs];
    }
    if (_oldestPost && !_isRefreshing) {
        [mainQuery whereKey:@"createdAt" lessThan:_oldestPost];
    }
    [mainQuery setLimit:6];
    _isLoading = YES;
    static BOOL _displayedAlert = NO;
    [mainQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        _isLoading = NO;
        if (_isRefreshing) {
            [_objectIDs removeAllObjects];
            [_objects removeAllObjects];
            _oldestPost = nil;
        }
        if (!error) {
            for (PFObject *object in objects) {
                [_objects addObject:object];
                [_objectIDs addObject:object.objectId];
                if ([object.createdAt timeIntervalSinceDate:_oldestPost] > 0) {
                    _oldestPost = [[NSDate alloc] initWithTimeInterval:0 sinceDate:object.createdAt];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self.tableView reloadData];
            });
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
        [self.refreshControl endRefreshing];
        _isRefreshing = NO;
    }];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_objects count]) {
        return 0;
    }
    Post *currentPost = [[Post alloc] initWithObject:[_objects objectAtIndex:indexPath.row]];
    CGSize constraint = CGSizeMake(280.0f, 20000.0f);
    CGSize size = [currentPost.caption sizeWithFont:[UIFont boldSystemFontOfSize:17.0] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    return 280+30+3+25+size.height;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height - scrollView.contentOffset.y < (self.view.bounds.size.height)) {
        if (!_isLoading) {
            [self loadObjects];
        }
    }
}

# pragma mark - targets

- (IBAction)newPost:(id)sender{
    [self performSegueWithIdentifier:@"pushDetails" sender:self];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    currentLocation = [locations lastObject];
    NSLog(@"%f, %f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
    if (currentLocation.coordinate.longitude != 0 && currentLocation.coordinate.latitude != 0) {
        [locationManager stopUpdatingLocation];
    }
    _isRefreshing = YES;
    [self loadObjects];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showComments"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *currentPost = [[Post alloc] initWithObject:(PFObject *)[_objects objectAtIndex:indexPath.row]];
        CommentsTableViewController *destViewController = segue.destinationViewController;
        destViewController.post = currentPost;
    }
}
@end
