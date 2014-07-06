//
//  PFFeedTableViewController.m
//  PicYak
//
//  Created by William Emmanuel on 7/2/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "PFFeedTableViewController.h"
#import "CommentsTableViewController.h"
#import <math.h>

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
    //[self loadObjects];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)refreshPulled {
    if (_isLoading)
        return;
    [locationManager startUpdatingLocation];
    _isRefreshing = YES;
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
    PFGeoPoint *southWest = [self findPointWithDistance:5000.0 andBearing:225.0];
    PFGeoPoint *northEast = [self findPointWithDistance:5000.0 andBearing:45.0];
    
    PFQuery *mainQuery = [PFQuery queryWithClassName:@"Post"];
    [mainQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    [mainQuery orderByDescending:@"createdAt"];
    //if ([_objectIDs count] > 0 && !_isRefreshing) {
    //  [mainQuery whereKey:@"objectId" notContainedIn:_objectIDs];
    //}
    //if (_oldestPost && !_isRefreshing) {
    //  [mainQuery whereKey:@"createdAt" lessThan:_oldestPost];
    //}
    [mainQuery setLimit:6];
    [mainQuery setSkip:_objects.count];
    _isLoading = YES;
    [mainQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        _isLoading = NO;
        if (_isRefreshing) {
            // [_objectIDs removeAllObjects];
            [_objects removeAllObjects];
            _isRefreshing = NO;
            [self.tableView reloadData];
            // _oldestPost = nil;
            // [self.tableView reloadData];
        }
        if (!error) {
            for (PFObject *object in objects) {
                [_objects addObject:object];
                //    [_objectIDs addObject:object.objectId];
                //   if ([object.createdAt timeIntervalSinceDate:_oldestPost] > 0) {
                //       _oldestPost = [[NSDate alloc] initWithTimeInterval:0 sinceDate:object.createdAt];
                //   }
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
    CGSize size = [currentPost.caption sizeWithFont:[UIFont boldSystemFontOfSize:17.0] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    return 280+30+3+25+size.height;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height - scrollView.contentOffset.y < (self.view.bounds.size.height)) {
        if (!_isLoading) {
            [self loadObjects];
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

- (IBAction)newPost:(id)sender{
    [self performSegueWithIdentifier:@"pushDetails" sender:self];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    currentLocation = [locations lastObject];
    NSLog(@"%f, %f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
    //if (currentLocation.coordinate.longitude != 0 && currentLocation.coordinate.latitude != 0) {
    [locationManager stopUpdatingLocation];
    //}
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

