//
//  ViewController.m
//  Camera
//
//  Created by Pongsakorn Cherngchaosil on 11/21/15.
//  Copyright © 2015 Pongsakorn Cherngchaosil. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
   AVSpeechSynthesizer *mySynthesizer;
}

@property (weak,nonatomic) IBOutlet UIImageView *imageView;
@property (weak,nonatomic) IBOutlet UIButton *takePictureButton;
@property (strong,nonatomic) MPMoviePlayerController *moviePlayerController;
@property (strong, nonatomic) UIImage *image;
@property (strong,nonatomic) NSURL *movieURL;
@property (copy,nonatomic) NSString *lastChosenMediaType;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
   [super viewDidLoad];
   // Do any additional setup after loading the view, typically from a nib.
   // Set up Text-To-Speech
   mySynthesizer = [[AVSpeechSynthesizer alloc]init]  ;
   
   if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
      self.takePictureButton.hidden = YES;
   }
}

- (void)viewDidAppear:(BOOL)animated{
   [super viewDidAppear:animated];
   [self updateDisplay];
}

/**
   This method shows the correct view based on the type of media that user selected
      - the image view for a photograph and the movie player for a movie.
   The image view is always present, but the move player is created and added to the user interface 
      only when the user picks a movie for the first itme.
 */
- (void) updateDisplay {
   if ([self.lastChosenMediaType isEqual:(NSString *)kUTTypeImage]) {
      self.imageView.image = self.image;
      self.imageView.hidden = NO;
      self.moviePlayerController.view.hidden = YES;
   } else if ([self.lastChosenMediaType isEqual:(NSString *)kUTTypeMovie]) {
      if (self.moviePlayerController == nil) {
         self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:self.movieURL];
         UIView *movieView = self.moviePlayerController.view;
         movieView.frame = self.imageView.frame;
         movieView.clipsToBounds = YES;
         [self.view addSubview:movieView];
      } else {
         self.moviePlayerController.contentURL = self.movieURL;
      }
      self.imageView.hidden = YES;
      self.moviePlayerController.view.hidden = NO;
      [self.moviePlayerController play];
   }
}

- (void)pickMediaFromSource:(UIImagePickerControllerSourceType)sourceType {
   NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
   if ([UIImagePickerController isSourceTypeAvailable:sourceType] && [mediaTypes count] > 0) {
      UIImagePickerController *picker = [[UIImagePickerController alloc]init];
      picker.mediaTypes = mediaTypes;
      picker.delegate =self;
      picker.allowsEditing = YES;
      picker.sourceType = sourceType;
      [self presentViewController:picker animated:YES completion:NULL];
   } else {
      UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error accessing media" message:@"Unsupported media source." preferredStyle:UIAlertControllerStyleAlert];
      UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
      [alertController addAction:okAction];
      [self presentViewController:alertController animated:YES completion:nil];
   }
}

- (void)didReceiveMemoryWarning {
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

- (IBAction)shootPictureOrVideo:(UIButton *)sender {
   [self pickMediaFromSource:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)selectExistingPictureOrVideo:(UIButton *)sender {
   [self pickMediaFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (IBAction)speakText:(id)sender {
   NSString *text = self.textLabel.text;
   AVSpeechUtterance *myTestUtterance = [[AVSpeechUtterance alloc]initWithString:text];
   [mySynthesizer speakUtterance:myTestUtterance];
   
}

- (IBAction)getTranslation:(id)sender {
   [PFCloud callFunctionInBackground:@"getPhoto" withParameters:@{} block:^(NSString *result, NSError *error) {
      if (!error) {
         NSLog(@"Success: %@", result);
         self.textLabel.text = result;
//         [PFCloud callFunctionInBackground:@"getPhotoData" withParameters:@{} block:^(NSString *result, NSError *error) {
//            if (!error) {
//               NSLog(@"Success: %@", result);
//               // Result is @"Cloud integeration is easy!"
//            } else
//               NSLog(@"Error: %@", error);
//         }];
      } else {
         NSLog(@"Error: %@", error);
      }
   }];
}

#pragma mark - Image Picker Controller delegate methods
- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
   self.lastChosenMediaType = info[UIImagePickerControllerMediaType];
   if ([self.lastChosenMediaType isEqual:(NSString *) kUTTypeImage]) {
      self.image = info[UIImagePickerControllerEditedImage];
      
      // Convert to JPEG with 50% quality
      NSData *data = UIImageJPEGRepresentation(self.image, 0.5f);
      PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:data];
      
      [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
         if (!error) {
            PFObject *newPhotoObject = [PFObject objectWithClassName:@"PhotoObject"];
            [newPhotoObject setObject:imageFile forKey:@"image"];
            [newPhotoObject setObject:@"ImageFile" forKey:@"ImageKey"];
            
            [newPhotoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
               if (!error) {
                  NSLog(@"saved");
               } else {
                  // error
                  NSLog(@"error: %@ %@", error, [error userInfo]);
               }
            }];
         }
      }];
   } else if ([self.lastChosenMediaType isEqual:(NSString *)kUTTypeMovie]) {
      self.movieURL = info[UIImagePickerControllerMediaURL];
   }
   [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
   [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
