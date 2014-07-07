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
    UIImagePickerController *imagePicker;
    UIImagePickerController *libraryPicker;
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
    keyboardVisible = NO;
    kOFFSET_FOR_KEYBOARD = 120.0;
    self.captionTextField.delegate = self;
    
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
    // Save PFFile
    NSString *caption = self.captionTextField.text;
    
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
                //[newPost setObject:expiration forKey:@"expiration"];
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
    if (keyboardVisible) {
       [self.captionTextField resignFirstResponder];
        return;
    }
    imagePicker = [[UIImagePickerController alloc] init];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.showsCameraControls = YES;
        imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(220, screenRect.size.height-50.0, 100, 30)];
        [button setTitle:@"Library" forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor clearColor]];
        [button addTarget:self action:@selector(gotoLibrary:) forControlEvents:UIControlEventTouchUpInside];
        
        [imagePicker.view addSubview:button];
        
    } else {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    [locationManager startUpdatingLocation];
    [self presentViewController:imagePicker animated:YES completion:NULL];
}
-(IBAction)gotoLibrary:(id)sender
{
    libraryPicker = [[UIImagePickerController alloc] init];
    libraryPicker.allowsEditing = YES;
    [libraryPicker.view setFrame:CGRectMake(0, 80, 320, 350)];
    [libraryPicker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    [libraryPicker setDelegate:self];
    
    [imagePicker presentViewController:libraryPicker animated:YES completion:nil];
}


# pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)completePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *photo = info[UIImagePickerControllerEditedImage];
    CGSize imageSize = CGSizeMake(280.0, 280.0);
    photo = [self squareImageWithImage:photo scaledToSize:imageSize];
    // Launch post view controller here
    NSData *imageData = UIImageJPEGRepresentation(photo, .20f);
    imageToSave = [PFFile fileWithName:@"PostPicture.jpg" data:imageData];
    [self.addImageButton setImage:photo forState:UIControlStateNormal];
    if(libraryPicker != NULL){
         [libraryPicker dismissViewControllerAnimated:NO completion:NULL];
    }
     [imagePicker dismissViewControllerAnimated:YES completion:NULL];
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
