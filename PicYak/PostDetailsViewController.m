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
    double kOFFSET_FOR_KEYBOARD;
    BOOL keyboardVisible;
    BOOL setImage;
    UIImagePickerController *imagePicker;
    UIImagePickerController *libraryPicker;
    NSString *uniqueDeviceIdentifier;
    
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
    setImage = NO;
    keyboardVisible = NO;
    kOFFSET_FOR_KEYBOARD = 140.0;
    self.captionTextField.delegate = self;
    
    uniqueDeviceIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
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
    [self.addImageButton setImage:[UIImage imageNamed:@"camera44.png"] forState:UIControlStateNormal];
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    self.expiresField.inputView = picker;
    expirationChoices = @[@" ", @"1 hour",@"2 hours",@"4 hours",@"1 day",@"2 days", @"1 week", @"never"];
    [picker selectRow:0 inComponent:0 animated:YES];
    
     

}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


- (IBAction)savePostPressed:(id)sender {
    
   /* NSDate *expiration = [NSDate date];
    
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
    }*/
    
    // Save PFFile
    if(!setImage){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoops" message:@"You can't submit a post with no photo jah feel?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
        [alert show];
        
    }
    else{
    NSString *caption = self.captionTextField.text;
    
    [imageToSave saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            CLLocationCoordinate2D coordinate = [currentLocation coordinate];
            PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                          longitude:coordinate.longitude];
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *newPost = [PFObject objectWithClassName:@"Post"];
            [newPost setObject:imageToSave forKey:@"picture"];
            newPost[@"score"] = @0;
            newPost[@"reports"] = @0;
            newPost[@"posterDeviceId"] = uniqueDeviceIdentifier;
            [newPost setObject:geoPoint forKey:@"location"];
            if (![self.expiresField.text isEqualToString:@"never"] && ![self.expiresField.text isEqualToString:@""]) {
                //[newPost setObject:expiration forKey:@"expiration"];
            }
            newPost[@"caption"] = caption;
            [newPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    
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
    [self.navigationController popToRootViewControllerAnimated:YES];
    //self.captionTextField.text = @"";
    }
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
    if (keyboardVisible) {
       [self.captionTextField resignFirstResponder];
        return;
    }
    
    // Commented out action sheet--just image taking with camera
    
//    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
//                            @"Take Photo",
//                            @"Choose Existing",
//                            nil];
//    popup.tag = 1;
//    [popup showInView:[UIApplication sharedApplication].keyWindow];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.showsCameraControls = YES;
        imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        imagePicker.delegate = self;
        imagePicker.allowsEditing = YES;
        [locationManager startUpdatingLocation];
        [self presentViewController:imagePicker animated:YES completion:NULL];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Camera not available Jah feel?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
        [alert show];
    }
    
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    imagePicker = [[UIImagePickerController alloc] init];
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:{
                    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
                        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                        imagePicker.showsCameraControls = YES;
                        imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                        imagePicker.delegate = self;
                        imagePicker.allowsEditing = YES;
                        [locationManager startUpdatingLocation];
                        [self presentViewController:imagePicker animated:YES completion:NULL];
                        break;
                    }
                    else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Camera not available Jah feel?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
                        [alert show];
                        break;
                    }
                    
                    
                    }
                case 1:{
                    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    imagePicker.delegate = self;
                    imagePicker.allowsEditing = YES;
                    [locationManager startUpdatingLocation];
                    [self presentViewController:imagePicker animated:YES completion:NULL];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}



# pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)completePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *photo = info[UIImagePickerControllerEditedImage];
    CGSize imageSize = CGSizeMake(280.0, 280.0);
    photo = [self squareImageWithImage:photo scaledToSize:imageSize];
    // Launch post view controller here
    NSData *imageData = UIImageJPEGRepresentation(photo, .6f);
    imageToSave = [PFFile fileWithName:@"PostPicture.jpg" data:imageData];
    [self.addImageButton setImage:photo forState:UIControlStateNormal];
    self.addImageButton.layer.borderColor = [UIColor colorWithRed:.616 green:.792 blue:.875 alpha:1.0].CGColor;
    self.addImageButton.layer.borderWidth = 6;
     [imagePicker dismissViewControllerAnimated:YES completion:NULL];
    setImage = YES;
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)cancelPicker {
    [cancelPicker dismissViewControllerAnimated:YES completion:NULL];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    currentLocation = [locations lastObject];
    [locationManager stopUpdatingLocation];
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

- (void)didTakePicture:(UIImage *)picture
{
    UIImage * flippedImage = [UIImage imageWithCGImage:picture.CGImage scale:picture.scale orientation:UIImageOrientationLeftMirrored];
    
    picture = flippedImage;
}

- (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        delta = (ratio*image.size.width - ratio*image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.height;
        delta = (ratio*image.size.height - ratio*image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width) + delta,
                                 (ratio * image.size.height) + delta);
    
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

-(void)dismissKeyboard {
    [self.captionTextField resignFirstResponder];
    [self.expiresField resignFirstResponder];
}

-(void)keyboardWillShow {
    keyboardVisible = YES;
    // Animate the current view out of the way
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardWillHide {
    keyboardVisible = NO;
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}
/*
-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    if  (self.view.frame.origin.y >= 0)
    {
            [self setViewMovedUp:YES];
    }
}
*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.captionTextField resignFirstResponder];
    return YES;
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}


@end
