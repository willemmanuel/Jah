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

@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL isRefreshing;

@end
