//
//  PYFeedViewController.m
//  PicYak
//
//  Created by Rebecca Mignone on 6/28/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//
#import <Parse/Parse.h>
#import "FeedTableViewController.h"
#import "Post.h"
#import "CommentsTableViewController.h"

@interface FeedTableViewController (){
    NSMutableArray *posts;
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSString *uniqueDeviceIdentifier;
}

@end

@implementation FeedTableViewController



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    uniqueDeviceIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.allPosts =[[NSMutableArray alloc] init];
    locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    [self queryForAllPostsNearLocation];
    
    UIBarButtonItem *takePicture = [[UIBarButtonItem alloc]initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(newPost:)];
    self.navigationItem.rightBarButtonItem = takePicture;
}

- (void) viewDidAppear:(BOOL)animated
{
    
}

- (IBAction)newPost:(id)sender{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.showsCameraControls = YES;
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    picker.delegate = self;
    picker.allowsEditing = YES;

    [self presentViewController:picker animated:YES completion:NULL];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.allPosts count];
}

- (void)queryForAllPostsNearLocation{
	PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    NSLog(@"%f, %f",currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
	if (currentLocation == nil) {
		NSLog(@"%s got a nil location!", __PRETTY_FUNCTION__);
	}
    
	// If no objects are loaded in memory, we look to the cache first to fill the table
	// and then subsequently do a query against the network.
	if ([self.allPosts count] == 0) {
		query.cachePolicy = kPFCachePolicyCacheThenNetwork;
	}
    
	// Query for posts sort of kind of near our current location.
	PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
    [query orderByDescending:@"createdAt"];
	[query whereKey:@"location" nearGeoPoint:point withinKilometers:5.28];
	//query.limit = 10;
    
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error) {
			NSLog(@"error in geo query!"); // todo why is this ever happening?
		} else {
			// We need to make new post objects from objects,
			// and update allPosts and the map to reflect this new array.
			// But we don't want to remove all annotations from the mapview blindly,
			// so let's do some work to figure out what's new and what needs removing.
            
			// 1. Find genuinely new posts:
			//NSMutableArray *newPosts = [[NSMutableArray alloc] initWithCapacity:kPAWWallPostsSearch];
            NSMutableArray *newPosts = [[NSMutableArray alloc] init];
			// (Cache the objects we make for the search in step 2:)
			NSMutableArray *allNewPosts = [[NSMutableArray alloc] init];
			for (PFObject *object in objects) {
				Post *newPost = [[Post alloc] initWithObject:object];
				[allNewPosts addObject:newPost];
				BOOL found = NO;
				for (Post *currentPost in self.allPosts) {
					if ([newPost equalToPost:currentPost]) {
						found = YES;
					}
				}
				if (!found) {
					[newPosts addObject:newPost];
				}
			}
			// newPosts now contains our new objects.
            
			// 2. Find posts in allPosts that didn't make the cut.
			NSMutableArray *postsToRemove = [[NSMutableArray alloc] init];
			for (Post *currentPost in self.allPosts) {
				BOOL found = NO;
				// Use our object cache from the first loop to save some work.
				for (Post *allNewPost in allNewPosts) {
					if ([currentPost equalToPost:allNewPost]) {
						found = YES;
					}
				}
				if (!found) {
					[postsToRemove addObject:currentPost];
				}
			}
			
			[self.allPosts addObjectsFromArray:newPosts];
			[self.allPosts removeObjectsInArray:postsToRemove];
            NSSortDescriptor *sortDescriptor =
            [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                        ascending:NO];
            NSArray *descriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
            NSArray *sortedArray = [self.allPosts sortedArrayUsingDescriptors:descriptors];
            self.allPosts = [sortedArray mutableCopy];

            [self.tableView reloadData];
		}
	}];
}

- (void)refreshTable
{
    [locationManager startUpdatingLocation];
    [self queryForAllPostsNearLocation];
    [self.refreshControl endRefreshing];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[PostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    Post *currentPost = [self.allPosts objectAtIndex:indexPath.row];
    cell.picture.image = currentPost.picture;
    cell.score.text = [NSString stringWithFormat:@"%d",currentPost.score];
    cell.caption.text = currentPost.postId;
    cell.delegate = self;
    cell.post = currentPost; 
    return cell;
}

# pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [locationManager startUpdatingLocation];
    UIImage *photo = info[UIImagePickerControllerEditedImage];
    // Launch post view controller here
    NSData *imageData = UIImageJPEGRepresentation(photo, .05f);
    PFFile *imageFile = [PFFile fileWithName:@"PostPicture.jpg" data:imageData];
    
    //HUD creation here (see example for code)
    
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Hide old HUD, show completed HUD (see example for code)
            [locationManager startMonitoringSignificantLocationChanges];
            currentLocation = locationManager.location;
            [locationManager stopMonitoringSignificantLocationChanges];
            CLLocationCoordinate2D coordinate = [currentLocation coordinate];
            PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                          longitude:coordinate.longitude];
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *newPost = [PFObject objectWithClassName:@"Post"];
            [newPost setObject:imageFile forKey:@"picture"];
            [newPost setObject:geoPoint forKey:@"location"];
            [newPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    //code for successful save
                    
                }
                else{
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    
                }
            }];
        }
        else{
            // Log details of the failure
           
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
    }];
     [picker dismissViewControllerAnimated:YES completion:NULL];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    currentLocation = [locations lastObject];
    [locationManager stopUpdatingLocation];
}

# pragma mark - Post table view cell delegate methods

-(void)upvoteOrDownvoteTapped:(PostTableViewCell*)postTableViewCell {
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showComments"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CommentsTableViewController *destViewController = segue.destinationViewController;
        destViewController.post = [self.allPosts objectAtIndex:indexPath.row];
    }
}

@end
