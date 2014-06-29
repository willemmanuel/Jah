//
//  PYFeedViewController.h
//  PicYak
//
//  Created by Rebecca Mignone on 6/28/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PostTableViewCell.h"
#import "Post.h"

@interface FeedTableViewController : UITableViewController <PostTableViewCellDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate>

@property (nonatomic,strong) NSMutableArray *allPosts;

@end
