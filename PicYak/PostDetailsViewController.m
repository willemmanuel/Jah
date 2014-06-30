//
//  PostDetailsViewController.m
//  PicYak
//
//  Created by Rebecca Mignone on 6/29/14.
//  Copyright (c) 2014 Mignone. All rights reserved.
//

#import "PostDetailsViewController.h"
#import <Parse/Parse.h>
@interface PostDetailsViewController (){
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    PFFile *imageToSave;
}

@end

@implementation PostDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.captionTextView.delegate = self;
    imageToSave = [[PFFile alloc]init];
    locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}
- (IBAction)savePostPressed:(id)sender {
    // Save PFFile
    [imageToSave saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            CLLocationCoordinate2D coordinate = [currentLocation coordinate];
            PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                          longitude:coordinate.longitude];
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *newPost = [PFObject objectWithClassName:@"Post"];
            [newPost setObject:imageToSave forKey:@"picture"];
            [newPost setObject:geoPoint forKey:@"location"];
            newPost[@"caption"] = self.captionTextView.text;
            [newPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
                else{
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        }
        else{
            [self.navigationController popToRootViewControllerAnimated:YES];
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)cancelPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (IBAction)loadImagePressed:(id)sender {
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
    [locationManager startUpdatingLocation];
    [self presentViewController:picker animated:YES completion:NULL];
}

# pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *photo = info[UIImagePickerControllerEditedImage];
    // Launch post view controller here
    NSData *imageData = UIImageJPEGRepresentation(photo, .05f);
    imageToSave = [PFFile fileWithName:@"PostPicture.jpg" data:imageData];
    [self.addImageButton setImage:photo forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    currentLocation = [locations lastObject];
    [locationManager stopUpdatingLocation];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView setText:@""];
    UIView *containerView = (UIView *)[self.view viewWithTag:1];
    [UIView animateWithDuration:0.3 animations:^{
        containerView.frame = CGRectMake(0.0f, -120.0f, containerView.frame.size.width, containerView.frame.size.height);
    }];
    
}

- (void)textViewDidEndEditing:(UITextField *)textField {

}
-(BOOL) textViewShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
-(void)dismissKeyboard {
    UIView *containerView = (UIView *)[self.view viewWithTag:1];
    [UIView animateWithDuration:0.3 animations:^{
        containerView.frame = CGRectMake(0.0f, 0.0f, containerView.frame.size.width, containerView.frame.size.height);
    }];

    [self.captionTextView resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
