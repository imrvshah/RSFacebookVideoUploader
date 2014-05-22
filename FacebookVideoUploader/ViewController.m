//
//  ViewController.m
//  FacebookVideoUploader
//
//  Created by ravi shah on 5/21/14.
//  Copyright (c) 2014 ravi shah. All rights reserved.
//

#import "ViewController.h"
#import <FacebookSDK/FacebookSDK.h>
@interface ViewController ()
- (IBAction)btnUploadVideoClicked:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnUploadVideoClicked:(id)sender {
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        
        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          // Handler for session state changes
                                          // This method will be called EACH time the session state changes,
                                          // also for intermediate states and NOT just when the session open
                                          [self sessionStateChanged:session state:state error:error];
                                      }];
        
        
    }
    else
    {
        // If the session state is any of the two "open" states when the button is clicked
        if (FBSession.activeSession.state == FBSessionStateOpen
            || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
            
            // Close the session and remove the access token from the cache
            // The session state handler (in the app delegate) will be called automatically
            [FBSession.activeSession closeAndClearTokenInformation];
            
            // If the session state is not any of the two "open" states when the button is clicked
        } else {
            // Open a session showing the user the login UI
            // You must ALWAYS ask for public_profile permissions when opening a session
            [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                               allowLoginUI:YES
                                          completionHandler:
             ^(FBSession *session, FBSessionState state, NSError *error) {
                 
                // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
                 [self sessionStateChanged:session state:state error:error];
             }];
        }
        
    }

}
// This method will handle ALL the session state changes in the app
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        NSLog(@"Session opened");
        if ([FBSession.activeSession.permissions
             indexOfObject:@"publish_actions"] == NSNotFound)
        {
            // No permissions found in session, ask for it
            [FBSession.activeSession
             reauthorizeWithPublishPermissions:
             [NSArray arrayWithObject:@"publish_actions"]
             defaultAudience:FBSessionDefaultAudienceFriends
             completionHandler:^(FBSession *session, NSError *error) {
                 if (!error)
                 {
                    // Show the user the logged-in UI
                     [self publishVideo];
                     return;
                     
                     
                 }
             }];
        }
        else
        {
            [self publishVideo];
            return;
        }
        
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        // If the session is closed
        NSLog(@"Session closed");
        // Show the user the logged-out UI
        
    }
    
    // Handle errors
    if (error){
        NSLog(@"Error");
        NSString *alertText;
        NSString *alertTitle;
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                
                
                // For simplicity, here we just show a generic message for all other errors
                // You can learn how to handle other errors using our guide: https://developers.facebook.com/docs/ios/errors
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                
            }
        }
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        // Show the user the logged-out UI
        
    }
}
-(void)publishVideo
{
    // If permissions granted, publish the story
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Ravi_screen" ofType:@"mp4"];
    NSData *videoData = [NSData dataWithContentsOfFile:filePath];
    NSString* videoName = [filePath lastPathComponent];


    NSDictionary *videoObject = @{
                                  @"title": @"RSFacebookVideoUploader",
                                  @"description": @"First Video Uploaded",
                                  videoName: videoData,
                                   @"contentType": @"video/mp4"
                                  };
    FBRequest *uploadRequest = [FBRequest requestWithGraphPath:@"me/videos"
                                                    parameters:videoObject
                                                    HTTPMethod:@"POST"];
    
    [uploadRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error)
            NSLog(@"Done: %@", result);
        else
            NSLog(@"Error: %@", error.localizedDescription);
    }];

}
@end
