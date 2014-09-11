//
//  PFFeedTableViewController.h
//  PicYak
//
//  Created by William Emmanuel on 7/2/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//
@import CoreData;

#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
#import "PostTableViewCell.h"

@interface PFFeedTableViewController : UITableViewController <UIImagePickerControllerDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate, PostTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic) BOOL newPostsAreLoading;
@property (nonatomic) BOOL topPostsAreLoading;
@property (nonatomic) BOOL hotPostsAreLoading;
@property (nonatomic) BOOL newPostsAreRefreshing;
@property (nonatomic) BOOL topPostsAreRefreshing;
@property (nonatomic) BOOL hotPostsAreRefreshing;
@property (nonatomic) BOOL processingVote;

@end
