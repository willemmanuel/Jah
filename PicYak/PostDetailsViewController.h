//
//  PostDetailsViewController.h
//  PicYak
//
//  Created by Rebecca Mignone on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface PostDetailsViewController : UIViewController <UITextViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *addImageButton;
@property (weak, nonatomic) IBOutlet UITextView *captionTextView;

@end
