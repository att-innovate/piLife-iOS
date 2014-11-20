//
//  ViewController.m
//  piLife
//
//  Created by Virginia Ng on 10/3/14.
//  Copyright (c) 2014 Virginia Ng. All rights reserved.
//

#import "ViewController.h"
#import "NSMutableURLRequest+BasicAuth.h"


#define kPickerHouse 1
#define kPickerDevice 2
#define kPickerValue 3

#define baseURL @"https://atlantafoundry-test.apigee.net"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#define getDevicesClientID @"CElTy869h5atDJpsWNGAKwGQOtZKrlOO"
#define getDevicesClientSecret @"K45Jo4upESKzpRVp"


@interface ViewController ()

@property (strong,nonatomic) NSArray *deviceArray;
@property (strong,nonatomic) NSArray *valueArray;

@property NSInteger pickerType;
@property NSInteger selectedDevice;
@property NSInteger selectedValue;
@property NSString *selectedHouseName;
@property NSString *accessToken;

@property ViewController *viewController;

@end

@implementation ViewController

@synthesize houseNameTxt = _houseNameTxt;
@synthesize selectDeviceTxt = _selectDeviceTxt;
@synthesize selectValueTxt = _selectValueTxt;

@synthesize deviceArray = _deviceArray;
@synthesize valueArray = _valueArray;
@synthesize pickerType = _pickerType;
@synthesize selectedDevice = _selectedDevice;
@synthesize selectedValue = _selectedValue;
@synthesize viewController = _viewController;
@synthesize selectedHouseName = _selectedHouseName;
@synthesize accessToken = _accessToken;
@synthesize activityIndicator = _activityIndicator;


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self getOAuth];
    
    _selectedDevice = -1;
    _selectedValue = -1;

    UIPickerView *devicePicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    devicePicker.delegate = self;
    devicePicker.dataSource = self;
    devicePicker.tag = kPickerDevice;
    [devicePicker setShowsSelectionIndicator:YES];
    _selectDeviceTxt.inputView = devicePicker;

    UIPickerView *valuePicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    valuePicker.delegate = self;
    valuePicker.dataSource = self;
    valuePicker.tag = kPickerValue;
    [valuePicker setShowsSelectionIndicator:YES];
    _selectValueTxt.inputView = valuePicker;
    
    _activityIndicatorView.alpha = 0.0;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIPickerView
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component {

    if (pickerView.tag == kPickerDevice) {
        return [_deviceArray count];
    } else if (pickerView.tag == kPickerValue) {
        return [_valueArray count];
    } else {
        return 0;
    }
}
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {

    NSDictionary *device = [[NSDictionary alloc] init];

    if (pickerView.tag == kPickerDevice) {
        device = [_deviceArray objectAtIndex:row];
        return [device objectForKey:@"deviceDescription"];
    } else if (pickerView.tag == kPickerValue) {
        return [_valueArray objectAtIndex:row];
    } else {
        return @"NONE";
    }

}

- (void) updateDataArrays {
    
    if (_selectedDevice >= 0) {
        NSDictionary *device =  [_deviceArray objectAtIndex:_selectedDevice];
        _valueArray = [device objectForKey:@"actionCmdOptions"];
    } else {
        _valueArray = nil;

    }

}
- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    NSDictionary *device = [[NSDictionary alloc] init];
    
    if (pickerView.tag == kPickerDevice) {
        _selectedDevice = row;
        device = [_deviceArray objectAtIndex:row];
        [_selectDeviceTxt setText:[device objectForKey:@"deviceDescription"]];
        [_selectValueTxt setText: @""];
        [self updateDataArrays];

        UIView *tempView = _selectValueTxt.inputView;
        if ([tempView isMemberOfClass:[UIPickerView class]]) {
            UIPickerView *tempPicker = (UIPickerView *)tempView;
            [tempPicker reloadAllComponents];
            if ([[device objectForKey:@"status"] isEqualToString:@"1"]) {
                [tempPicker selectRow:0 inComponent:0 animated:YES];
            } else {
                [tempPicker selectRow:1 inComponent:0 animated:YES];
                
            }
        }
        [_selectDeviceTxt resignFirstResponder];
    } else if (pickerView.tag == kPickerValue) {
        _selectedValue = row;
        [_selectValueTxt setText: [_valueArray objectAtIndex:row]];
        
       [_selectValueTxt resignFirstResponder];

    }
    
}

- (bool)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"text return");
    if (textField.tag == 1) {
        [self getDevices];
        [textField resignFirstResponder];
    }
    return NO;
}
#pragma mark - IBAction


- (IBAction)updateDeviceSetting:(id)sender {
    if (([_accessToken length] > 0) && ([_selectValueTxt.text length] > 0)){
        NSDictionary *device = [_deviceArray objectAtIndex:_selectedDevice];
        NSArray *choices = [device objectForKey:@"actionCmdOptions"];
        NSLog(@"value selected: %@", [choices objectAtIndex:_selectedValue]);
        
        NSDictionary *updateDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    _selectedHouseName, @"dlcTag",
                                    [device objectForKey:@"deviceName"], @"deviceTag",
                                    [device objectForKey:@"actionType"], @"actionType",
                                    [choices objectAtIndex:_selectedValue], @"action",
                                    nil];
        NSError *error;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:updateDict options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSString *urlString = [NSString stringWithFormat:@"%@%@", baseURL, @"/getDevices/cmd"];
        
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[jsonString length]] forHTTPHeaderField:@"Content-length"];
        [urlRequest setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        //        NSString *authValue = [NSString stringWithFormat:@"Bearer %@", _setValueAccessToken];
        NSString *authValue = [NSString stringWithFormat:@"Bearer %@", _accessToken];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        [self sendRequest:urlRequest];
    }
}
- (void)getDevices {
    if (_selectDeviceTxt) {
        NSString *txtEntered = _houseNameTxt.text;
        _selectedHouseName = [txtEntered stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog(@"Entered Device: %@", _selectedHouseName);
        [self showActivityIndicator];
        [self getDeviceInformation];
    }
    [_houseNameTxt resignFirstResponder];
}

- (IBAction)houseNameEntered:(id)sender {
    NSLog(@"house name: %@", _houseNameTxt.text);
    //[self getDevices];
}

- (IBAction)houseNameBeginChange:(id)sender {
    _selectedDevice = -1;
    _selectedValue = -1;
    _selectedHouseName = @"";
    _houseNameTxt.text = @"";
    _selectDeviceTxt.text = @"";
    _selectValueTxt.text = @"";
    
    _deviceArray = nil;
    _valueArray = nil;
    
    _selectDeviceTxt.enabled = NO;
    _selectValueTxt.enabled = NO;
    
}



#pragma mark - Connections

-(void) getOAuth{
    NSString* urlString = [NSString stringWithFormat:@"%@/oauth/client_credential/accesstoken?grant_type=client_credentials", baseURL];
    //    NSLog(@"jsonData: %@", sendString);
    NSLog(@"url: %@", urlString);
    NSString *authStr = nil;
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [urlRequest setHTTPMethod:@"POST"];
    authStr = [NSString stringWithFormat:@"%@:%@", getDevicesClientID, getDevicesClientSecret];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
    [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];

    [self sendRequest:urlRequest];
}

- (void)getDeviceInformation {
    if ([_accessToken length] == 0) {
        [self showActivityIndicator];
        _selectDeviceTxt.enabled = NO;
        _selectValueTxt.enabled = NO;
    }
    if (([_accessToken length] > 0) &&  ([_selectedHouseName length] > 0)){
        NSString* urlString = [NSString stringWithFormat:@"%@/getDevices/cmdsetchoices?dlcTag=%@", baseURL, _selectedHouseName];
        
        //    NSLog(@"jsonData: %@", sendString);
        NSLog(@"url: %@", urlString);
        NSString *authValue = [NSString stringWithFormat:@"Bearer %@", _accessToken];
        //
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        [urlRequest setHTTPMethod:@"GET"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        [self sendRequest:urlRequest];
    }
    
    
}

- (void) sendRequest:(NSURLRequest*) request {
    
    dispatch_async(kBgQueue, ^{
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        [self performSelectorOnMainThread:@selector(fetchedData:)
                               withObject:returnData waitUntilDone:YES];
    });
    
    
}

- (void) fetchedData:(NSData *) responseData {
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    NSString *clientID = [json objectForKey:@"client_id"];
    
    if ([json objectForKey:@"access_token"] != nil) {
        if ([clientID isEqualToString:getDevicesClientID] ) {
            _accessToken = [json objectForKey:@"access_token"];
            NSLog(@"access_token: %@", _accessToken);
            [self getDeviceInformation];
        }
    } else if ([json objectForKey:@"devices"] != nil) {
        _deviceArray = [json objectForKey:@"devices"];
        //[self updateDataArrays];
        UIView *tempView = _selectValueTxt.inputView;
        if ([tempView isMemberOfClass:[UIPickerView class]]) {
            UIPickerView *tempPicker = (UIPickerView *)tempView;
            [tempPicker reloadAllComponents];
        }
        [self hideActivityIndicator];
        _selectDeviceTxt.enabled = YES;
        _selectValueTxt.enabled = YES;
        

    } else if ([json objectForKey:@"deviceTag"] != nil) {
        NSLog(@"updated value!!!");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Successful" message:@"The device setting has been changed!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    
}

- (void) showActivityIndicator {
    [UIView animateWithDuration:0.3 animations:^{
        _activityIndicatorView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [_activityIndicator startAnimating];
    }];
}

- (void) hideActivityIndicator {
    [UIView animateWithDuration:0.3 animations:^{
        _activityIndicatorView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [_activityIndicator stopAnimating];
    }];
    
}
@end


