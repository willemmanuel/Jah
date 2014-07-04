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

@implementation PFFeedTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    self.parseClassName = @"Post";
    self.pullToRefreshEnabled = YES;
    self.paginationEnabled = YES;
    self.objectsPerPage = 6;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    uniqueDeviceIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    UIBarButtonItem *takePicture = [[UIBarButtonItem alloc]initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(newPost:)];
    self.navigationItem.rightBarButtonItem = takePicture;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [locationManager startUpdatingLocation];
}

- (PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
    static NSString *cellIdentifier = @"cell";
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[PostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
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
- (PFQuery *)queryForTable
{
    PFQuery *mainQuery = [PFQuery queryWithClassName:@"Post"];
    PFQuery *notExpiredQuery = [PFQuery queryWithClassName:@"Post"];
    [notExpiredQuery whereKey:@"expiration" greaterThanOrEqualTo:[NSDate date]];
    PFQuery *neverExpireQuery = [PFQuery queryWithClassName:@"Post"];
    [neverExpireQuery whereKeyDoesNotExist:@"expiration"];
    mainQuery = [PFQuery orQueryWithSubqueries:@[notExpiredQuery, neverExpireQuery]];
	PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
    [mainQuery orderByDescending:@"createdAt"];
	[mainQuery whereKey:@"location" nearGeoPoint:point withinKilometers:5.28];
    [mainQuery setLimit:6];
    return mainQuery;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self.objects count]) {
        return 40; 
    }
    Post *currentPost = [[Post alloc] initWithObject:[self.objects objectAtIndex:indexPath.row]];
    CGSize constraint = CGSizeMake(280.0f, 20000.0f);
    CGSize size = [currentPost.caption sizeWithFont:[UIFont boldSystemFontOfSize:17.0] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    return 280+30+3+25+size.height;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height - scrollView.contentOffset.y < (self.view.bounds.size.height)) {
        if (![self isLoading]) {
            [self loadNextPage];
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
    [self loadObjects:0 clear:YES];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showComments"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *currentPost = [[Post alloc] initWithObject:(PFObject *)[self objectAtIndexPath:indexPath]];
        CommentsTableViewController *destViewController = segue.destinationViewController;
        destViewController.post = currentPost;
    }
}
@end
