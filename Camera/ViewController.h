//
//  ViewController.h
//  Camera
//
//  Created by Pongsakorn Cherngchaosil on 11/21/15.
//  Copyright © 2015 Pongsakorn Cherngchaosil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKDropDown.h"

@interface ViewController : UIViewController <SKDropDownDelegate>
@property (strong, nonatomic) SKDropDown *dropDown;


- (IBAction)showOrHideDropDown:(id)sender;


@end

