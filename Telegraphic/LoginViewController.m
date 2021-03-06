//
//  LoginViewController.m
//  Telegraphic
//
//  Created by Ricardo Lopez on 9/6/14.
//  Copyright (c) 2014 Base Twelve. All rights reserved.
//

#import <CommonCrypto/CommonHMAC.h>
#import "LoginViewController.h"
#import "APIFunctions.h"
#import "SecretKeys.h"
#import "DrawViewController.h"
#import "ImagesTableViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize usernameField, passwordField, queue;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

-(void)loadRestOfView {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.bounds = self.view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor yellowColor] CGColor], (id)[[UIColor orangeColor] CGColor], nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    [self registerKeyboardNotifications];
    
    usernameField.delegate = self;
    passwordField.delegate = self;
    self.originalCenter = self.view.center;
    NSLog(@"%@", NSStringFromCGPoint(self.originalCenter));
    // Do any additional setup after loading the view from its nib.
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //check defaults and see if it is there
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *pass = [defaults objectForKey:@"Password"];
    NSString *username = [defaults objectForKey:@"Username"];
    
    queue = [[NSOperationQueue alloc] init];
    
    if(([pass length] != 0) && ([username length] != 0)) {
        [self logIn:username withPass:pass];
    } else {
        [self loadRestOfView];
    }
}

- (void) logIn:(NSString*)username withPass:(NSString*)pass {
    
    NSMutableURLRequest *req = [APIFunctions loginUser:[SecretKeys getURL] withUsername:username withPassHash:[self hashString:pass withSalt:username]];
    
    [NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        //if there is an error, return
        if(!error) {
            //[self unableToLog];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            
            if(dict && [[dict objectForKey:@"success"] boolValue]) {
                NSLog(@"Successfully logged in!");
                
                // Store the data
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
                [defaults setObject:username forKey:@"Username"];
                [defaults setObject:pass forKey:@"Password"];
                
                [defaults synchronize];
                
                //now get access token and send to the tab view controller
                NSString *accessToken = [dict objectForKey:@"accessToken"];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                    ImagesTableViewController *imagesVC =[[ImagesTableViewController alloc] initWithAccessToken:accessToken withNavigationController:self.navigationController];
                    
                    [self.navigationController setViewControllers:@[imagesVC]];
                }];
                
            } else {
                //[self unableToLog];
                [self loadRestOfView];
            }
        } else {
            [self loadRestOfView];
        }

    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//ui alert view
//-(void)unableToLog {
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Log In" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
//
//    [alert show];
//}
//
//-(void)unableToRegister {
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Register" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
//
//    [alert show];
//
//}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

- (IBAction)loginButton:(UIButton *)sender {
    
    //log in using function
    [self logIn:usernameField.text withPass:passwordField.text];
}

- (IBAction)creatAccountButton:(UIButton *)sender {
    NSMutableURLRequest *req = [APIFunctions registerUser:[SecretKeys getURL] withUsername:usernameField.text withPassHash:[self hashString:passwordField.text withSalt:usernameField.text] withPhoneNumb:usernameField.text];
    
    [NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        //if there is an error, return
        if(error) {
            //[self unableToRegister];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        if(dict && [[dict objectForKey:@"success"] boolValue]) {
            NSLog(@"Successfully registered the account");
            
            //now try to log in
            [self loginButton:sender];
        } else {
            //[self unableToRegister];
        }
        
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == usernameField) {
        [textField resignFirstResponder];
        [passwordField becomeFirstResponder];
    }
    else {
        [textField resignFirstResponder];
    }
    return YES;
}

/**
 * Register keyboard notifications.
 */
-(void) registerKeyboardNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(keyboardDidShow:)
                   name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self
               selector:@selector(keyboardWillHide:)
                   name:UIKeyboardWillHideNotification object:nil];
}


/**
 * Unregister keyboard notifications.
 */
-(void) unregisterKeyboardNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


- (void)keyboardDidShow:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    self.view.center = CGPointMake(self.originalCenter.x, [[UIScreen mainScreen] bounds].size.height / 2.3);
    [UIView commitAnimations];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    self.view.center = self.originalCenter;
    [UIView commitAnimations];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([usernameField isFirstResponder] && [touch view] != usernameField) {
        [usernameField resignFirstResponder];
    }
    else if ([passwordField isFirstResponder] && [touch view] != passwordField) {
        [passwordField resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

#pragma mark crypto
-(NSString *) hashString :(NSString *) data withSalt: (NSString *) salt {
    
    const char *cData = [data cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, nil, 0, cData, strlen(cData), cHMAC);
    
    NSString *hash;
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", cHMAC[i]];
    hash = output;
    return hash;
    
}

@end
