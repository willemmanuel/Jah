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
    NSArray *expirationChoices;
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
    [self.addImageButton setImage:[UIImage imageNamed:@"Camera.png"] forState:UIControlStateNormal];
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    self.expiresField.inputView = picker;
    expirationChoices = @[@" ", @"1 hour",@"2 hours",@"4 hours",@"1 day",@"2 days", @"1 week", @"never"];
    [picker selectRow:0 inComponent:0 animated:YES];
}
- (IBAction)savePostPressed:(id)sender {
    // Save PFFile
    NSString *caption = self.captionTextField.text;
    
    NSDate *expiration = [NSDate date];
    
    if ([self.expiresField.text isEqualToString:@"1 hour"]) {
        expiration = [expiration dateByAddingTimeInterval:1*60*60];
    } else if ([self.expiresField.text isEqualToString:@"2 hours"]) {
        expiration = [expiration dateByAddingTimeInterval:2*60*60];
    } else if ([self.expiresField.text isEqualToString:@"4 hours"]) {
        expiration = [expiration dateByAddingTimeInterval:4*60*60];
    } else if ([self.expiresField.text isEqualToString:@"1 day"]) {
        expiration = [expiration dateByAddingTimeInterval:24*60*60];
    } else if ([self.expiresField.text isEqualToString:@"2 days"]) {
        expiration = [expiration dateByAddingTimeInterval:48*60*60];
    } else if ([self.expiresField.text isEqualToString:@"1 week"]) {
        expiration = [expiration dateByAddingTimeInterval:7*24*60*60];
    } else {
        expiration = nil;
    }
    
    [imageToSave saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            CLLocationCoordinate2D coordinate = [currentLocation coordinate];
            PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                          longitude:coordinate.longitude];
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *newPost = [PFObject objectWithClassName:@"Post"];
            [newPost setObject:imageToSave forKey:@"picture"];
            [newPost setObject:geoPoint forKey:@"location"];
            if (![self.expiresField.text isEqualToString:@"never"] && ![self.expiresField.text isEqualToString:@""]) {
                [newPost setObject:expiration forKey:@"expiration"];
            }
            newPost[@"caption"] = caption;
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
    self.captionTextField.text = @"";
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
    if (imageToSave.name) {
        [self.captionTextField resignFirstResponder];
        return; 
    }
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
    self.addImageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.addImageButton.imageView.clipsToBounds = YES;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    currentLocation = [locations lastObject];
    [locationManager stopUpdatingLocation];
}

-(void)dismissKeyboard {
    [self.captionTextField resignFirstResponder];
    [self.expiresField resignFirstResponder];
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return expirationChoices.count;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return expirationChoices[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.expiresField.text = expirationChoices[row];
    [self.expiresField resignFirstResponder];
}

@end
