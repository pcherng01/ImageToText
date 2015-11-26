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

#import "AKPickerView.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AKPickerViewDataSource, AKPickerViewDelegate>
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

@property (nonatomic, strong) AKPickerView *pickerView;
@property (nonatomic, strong) NSArray *options;


@property (weak, nonatomic) IBOutlet UIButton *B_openList;

@property (nonatomic, strong) NSMutableArray *wordsArr;

@end

@implementation ViewController

- (void)viewDidLoad {
   [super viewDidLoad];
   self.B_openList.layer.cornerRadius = 5;
   
   self.wordsArr = [NSMutableArray arrayWithObjects:@"",@"",@"",@"", @"", nil];
   // Set up the picker view
   CGRect place = CGRectMake(10, 610, 100, 100);
   self.pickerView = [[AKPickerView alloc]initWithFrame:place];
   self.pickerView.delegate = self;
   self.pickerView.dataSource = self;
   self.pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
   [self.view addSubview:self.pickerView];
   
   self.pickerView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
   self.pickerView.highlightedFont = [UIFont fontWithName:@"HelveticaNeue" size:20];
   self.pickerView.interitemSpacing = 20.0;
   self.pickerView.fisheyeFactor = 0.001;
   self.pickerView.pickerViewStyle = AKPickerViewStyle3D;
   self.pickerView.maskDisabled = false;
   
   self.options = @[@"English", @"Spanish", @"French",@"Arabic", @"Portugese"];
   [self.pickerView reloadData];
   
   
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

- (IBAction)showOrHideDropDown:(id)sender {
   NSArray * arrListContent = @[@"Library", @"Camera", @"Get Info", @"Speak"];
   
   if(_dropDown == nil) {
      CGFloat dropDownListHeight = 160; //Set height of drop down list
      NSString *direction = @"down"; //Set drop down direction animation
      
      _dropDown = [[SKDropDown alloc]showDropDown:sender withHeight:&dropDownListHeight withData:arrListContent animationDirection:direction];
      _dropDown.delegate = self;
   }
   else {
      [_dropDown hideDropDown:sender];
      [self closeDropDown];
   }
}
- (void) skDropDownDelegateMethod: (SKDropDown *) sender {
   [self closeDropDown];
}
- (void)doOptionOne:(SKDropDown *)sender {
[self pickMediaFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
}
- (void)doOptionTwo:(SKDropDown *)sender {
   [self pickMediaFromSource:UIImagePickerControllerSourceTypeCamera];
}
- (void)doOptionThree:(SKDropDown *)sender {
   [PFCloud callFunctionInBackground:@"getPhoto" withParameters:@{} block:^(NSString *result, NSError *error) {
      if (!error) {
         NSLog(@"Success: %@", result);
         self.textLabel.text = result;
         self.wordsArr[0] = result;
         
         PFObject *newIdentifyObj = [PFObject objectWithClassName:@"IdentityObj"];
         [newIdentifyObj setObject:result forKey:@"identity"];
         [newIdentifyObj setObject:@"idenValue" forKey:@"idenKey"];
         
         [newIdentifyObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (!error) {
               NSLog(@"saved");
            } else {
               // error
               NSLog(@"error: %@ %@", error, [error userInfo]);
            }
         }];
         
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
- (void)doOptionFour:(SKDropDown *)sender {
   NSString *text = self.textLabel.text;
   AVSpeechUtterance *myTestUtterance = [[AVSpeechUtterance alloc]initWithString:text];
   [mySynthesizer speakUtterance:myTestUtterance];
   
}

-(void)closeDropDown{
   _dropDown = nil;
}

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView {
   return [self.options count];
}
- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item {
   return self.options[item];
}
- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item {
   NSLog(@"THis gets called");
   if ([self.wordsArr[item] length] != 0) {
      self.textLabel.text = self.wordsArr[item];
   }
         /*
          0 - ENG, 1 - SPN, 2 - FRN, 3 - ARB, 4 - POR
          */
         if (item == 1) {
            NSLog(@"This gets called");
         [PFCloud callFunctionInBackground:@"getTranslateSpanish" withParameters:@{} block:^(NSString *result, NSError *error) {
            if (!error) {
               NSLog(@"Success: %@", result);
               self.wordsArr[item] = result;
               self.textLabel.text = self.wordsArr[item];
            } else {
               NSLog(@"Error: %@", error);
            }
         }];
         }
         else if (item == 2) {
         [PFCloud callFunctionInBackground:@"getTranslateFrench" withParameters:@{} block:^(NSString *result, NSError *error) {
            if (!error) {
               NSLog(@"Success: %@", result);
               self.wordsArr[item] = result;
               self.textLabel.text = self.wordsArr[item];
            } else {
               NSLog(@"Error: %@", error);
            }
         }];
         }
         else if (item == 3) {
         [PFCloud callFunctionInBackground:@"getTranslateArabic" withParameters:@{} block:^(NSString *result, NSError *error) {
            if (!error) {
               NSLog(@"Success: %@     ", result);
               self.wordsArr[item] = result;
               self.textLabel.text = self.wordsArr[item];
            } else {
               NSLog(@"Error: %@", error);
            }
         }];
         }
         else if (item == 4) {
         [PFCloud callFunctionInBackground:@"getTranslatePortugese" withParameters:@{} block:^(NSString *result, NSError *error) {
            if (!error) {
               NSLog(@"Success: %@", result);
               self.wordsArr[item] = result;
               self.textLabel.text = self.wordsArr[item];
            } else {
               NSLog(@"Error: %@", error);
            }
         }];
         }
   
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

- (IBAction)getInfo:(id)sender {
   [PFCloud callFunctionInBackground:@"getPhoto" withParameters:@{} block:^(NSString *result, NSError *error) {
      if (!error) {
         NSLog(@"Success: %@", result);
         self.textLabel.text = result;
         self.wordsArr[0] = result;
         
         PFObject *newIdentifyObj = [PFObject objectWithClassName:@"IdentityObj"];
         [newIdentifyObj setObject:result forKey:@"identity"];
         [newIdentifyObj setObject:@"idenValue" forKey:@"idenKey"];
         
         [newIdentifyObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (!error) {
               NSLog(@"saved");
            } else {
               // error
               NSLog(@"error: %@ %@", error, [error userInfo]);
            }
         }];

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
- (IBAction)getTranslation:(id)sender {
   [PFCloud callFunctionInBackground:@"getTranslate" withParameters:@{} block:^(NSString *result, NSError *error) {
      if (!error) {
         NSLog(@"Success: %@", result);
         self.textLabel.text = result;
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
