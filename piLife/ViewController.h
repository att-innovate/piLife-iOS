//
//  ViewController.h
//  piLife
//
//  Created by Virginia Ng on 10/3/14.
//  Copyright (c) 2014 Virginia Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, NSURLConnectionDataDelegate>
@property (strong, nonatomic) IBOutlet UITextField *houseNameTxt;
@property (strong, nonatomic) IBOutlet UITextField *selectDeviceTxt;
@property (strong, nonatomic) IBOutlet UITextField *selectValueTxt;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIView *activityIndicatorView;

- (IBAction)updateDeviceSetting:(id)sender;
- (IBAction)houseNameEntered:(id)sender;
- (IBAction)houseNameBeginChange:(id)sender;

@end

