//
//  PostDetailsViewController.h
//  PicYak
//
//  Created by Rebecca Mignone on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface PostDetailsViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *addImageButton;
@property (weak, nonatomic) IBOutlet UITextField *captionTextField;
@property (weak, nonatomic) IBOutlet UITextField *expiresField;


@end
