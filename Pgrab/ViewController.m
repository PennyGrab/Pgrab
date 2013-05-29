//
//  ViewController.m
//  Pgrab
//
//  Created by Mitch Stewart on 5/8/13.
//  Copyright (c) 2013 Mitch Stewart. All rights reserved.
//

#import "ViewController.h"
#import "LoginViewController.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#include <unistd.h>

#define USERID_KEY @"PGuserid"
#define USERNAME_KEY @"PGusername"
#define PASSWD_KEY @"PGpasswd"

// GLOBAL Class to save the user login info
//
@interface User : NSObject {
    int userid;
    NSString *username;
    NSTimer *timer;
    UIViewController *mainView;
    UILabel *credits;
    UILabel *bcredits;
    NSString *force_reload;
    bool updateDone;
    NSURLConnection *connUpdates;    
}

@property (nonatomic) int userid;
@property (nonatomic) bool updateDone;
@property (strong,nonatomic) NSString *username;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic)  UIViewController *mainView;
@property (strong, nonatomic) UILabel *credits;
@property (strong, nonatomic) UILabel *bcredits;
@property (strong, nonatomic) NSString *force_reload;
@property (strong, nonatomic) NSURLConnection *connUpdates;

+ (User *)Uinfo;
@end


// GLOBAL Class to save the user login info
//
@implementation User

@synthesize userid;
@synthesize username;
@synthesize timer;
@synthesize mainView;
@synthesize credits;
@synthesize bcredits;
@synthesize force_reload;
@synthesize updateDone;
@synthesize connUpdates;

static User *Uinfo = nil;

//#pragma mark -
//#pragma mark Singleton Methods

+(User *)Uinfo {
    static dispatch_once_t pred;    
    dispatch_once(&pred, ^{
        Uinfo = [[User alloc] init];
        Uinfo.userid = 0;
        Uinfo.username = nil;
        Uinfo.timer = 0;
        Uinfo.mainView = nil;
        Uinfo.credits = nil;
        Uinfo.bcredits = nil;
        Uinfo.force_reload = nil;
        Uinfo.updateDone = YES;
        Uinfo.connUpdates = nil;
    });
    return Uinfo;
}
@end


// LOGIN SCREEN VIEW
//
@interface LoginViewController ()

- (IBAction)Login:(id)sender;

- (void) LoginOk;

@property (strong, nonatomic) IBOutlet UITextField *passwd1;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *passwd2;
@property (strong, nonatomic) IBOutlet UITextField *uname2;
@property (strong, nonatomic) IBOutlet UIButton *Register;
@property (strong, nonatomic) IBOutlet UITextField *uname1;

@end

// LOGIN SCREEN VIEW
//
@implementation LoginViewController

// callback for new users
//
- (IBAction)Register:(id)sender {
    
    NSString* DEF_EMAIL = @"Email Address";
    NSString* UEMAIL = _email.text;
    
    NSString* DEF_USR = @"Screen Name";
    NSString* USR = _uname2.text;
    
    NSString* DEF_PWD = @"Password";
    NSString* UPWD = _passwd2.text;
    
    if ( [UEMAIL isEqualToString: DEF_EMAIL] )
    {
        UEMAIL = @"";
    }
    if ( [USR isEqualToString: DEF_USR] )
    {
        USR = @"";
    }
    if ( [UPWD isEqualToString: DEF_PWD] )
    {
        UPWD = @"";
    }
    
    NSString *fil = @"http://192.168.0.196/pg_mobile_lib.php?register=1";
    
    NSString *URL = [NSString stringWithFormat:
                     @"%@&reg_email=%@&uname=%@&passwd=%@",fil,
                     UEMAIL,USR,UPWD];
    
    //NSLog(@"register URL: %@",URL);
    //return;
    
    NSURL *loginURL = [NSURL URLWithString: URL];
    
    dispatch_queue_t LoginQueue = dispatch_queue_create("com.pg.login", 0);
    
    dispatch_async(LoginQueue,
                   ^{NSData* data = [NSData dataWithContentsOfURL: loginURL];
                       [self performSelectorOnMainThread:@selector(fetchLoginData:) withObject:
                        data waitUntilDone:YES];
                   });
   
    
}

// LOGIN callback for returning users
//
- (IBAction)Login:(id)sender {
    
    NSString* DEF_EMAIL = @"Email Address";
    NSString* UEMAIL = _email.text;
    
    NSString* DEF_USR = @"Screen Name";
    NSString* USR = _uname1.text;
    
    NSString* DEF_PWD = @"Password";
    NSString* UPWD = _passwd1.text;
    
    if ( [UEMAIL isEqualToString: DEF_EMAIL] )
    {
        UEMAIL = @"";
    }
    if ( [USR isEqualToString: DEF_USR] )
    {
        USR = @"";
    }
    if ( [UPWD isEqualToString: DEF_PWD] )
    {
        UPWD = @"";
    }
    
    NSString *fil = @"http://192.168.0.196/pg_mobile_lib.php?login=1";
    
    NSString *URL = [NSString stringWithFormat:
                     @"%@&reg_email=%@&uname=%@&passwd=%@",fil,
                     UEMAIL,USR,UPWD];
    
    NSURL *loginURL = [NSURL URLWithString: URL];
    
    dispatch_queue_t LoginQueue = dispatch_queue_create("com.pg.login", 0);
   
    // pass login info to server...
    //
    dispatch_async(LoginQueue,
                   ^{NSData* data = [NSData dataWithContentsOfURL: loginURL];
                       [self performSelectorOnMainThread:@selector(fetchLoginData:) withObject:
                        data waitUntilDone:YES];
                   });
    
    
}

// OK callback for Alert message
//
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // close the LOGIN view
    //
    [self dismissViewControllerAnimated:YES completion:nil];
    
    User *uinfo = [User Uinfo]; // GLOBAL user login info
    
    uinfo.force_reload = nil;
    
    uinfo.timer = [NSTimer scheduledTimerWithTimeInterval:.65 target:uinfo.mainView selector:@selector(getUpdates) userInfo:nil repeats:YES];
}

// get LOGIN results from server
//
- (void) fetchLoginData:(NSData *) dat
{
    NSError* err;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:dat
                          options:NSJSONReadingAllowFragments
                          error: &err];
    
    NSString *res = [json objectForKey:@"result"];
    NSString* OK = @"Y";
    NSString* BAD = @"N";
    NSString *result = nil;
    NSString* str = nil;
    NSString* username = nil;
    NSArray* data = [res componentsSeparatedByString: @"|"];
    int userid = 0;
    int cnt = 0;
    
    for (str in data)
    {
        if ( cnt == 0 )
            result = str;
        else if ( cnt == 1 )
            userid = [str intValue];
        else if ( cnt == 2 )
            username = str;
        cnt++;
    }
    
    NSLog(@"LOGIN result: %@ userid: %d name: %@",result,userid,username);
    
    // this was a good login
    //
    if ( [result isEqualToString:OK] )
    {
        User *uinfo = [User Uinfo]; // GLOBAL user login info
        
        uinfo.userid = userid; // save userid
        uinfo.username = username; // save username
        
        // pointer to standart user defaults
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *uid = [NSNumber numberWithInt:userid];
        NSString* PASSWD = nil;
        
        if ( ![_passwd1.text isEqualToString:@"Password"] && [_passwd1.text length] > 1 )
            PASSWD = _passwd1.text;
        else if ( ![_passwd2.text isEqualToString:@"Password"]  && [_passwd2.text length] > 1 ) PASSWD = _passwd2.text;

        // Save the username and userid so this guy can auto-login the next time
        //
        [defaults setObject:uid forKey:USERID_KEY];
        [defaults setObject:username forKey:USERNAME_KEY];
        [defaults setObject:PASSWD forKey:PASSWD_KEY];
        
        // do not forget to save changes
        [defaults synchronize];

        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Login Message"
                                                       message:[NSString stringWithFormat:@"You're logged in!"]
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        
        [alert show];
    }
    else if ( [result isEqualToString:BAD] ) // invalid login - bad username or passwd
    {
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Login Message"
                                                       message:[NSString stringWithFormat:@"Invalid UserName or Password."]
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        
        [alert show];
    }
    else // other errors (could be a database error)
    {
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Login Message"
                                                       message:[NSString stringWithFormat:@"Oops the server is reporting a problem: %@",result]
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        
        [alert show];        
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSLog(@"Loading LOGIN SCREEN!");
    
    // pointer to standart user defaults
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    if ( defaults != nil )
    {
        // getting an NSString
        NSString *username = [defaults stringForKey:USERNAME_KEY];
        NSString *passwd = [defaults stringForKey:PASSWD_KEY];
        
        // getting an NSInteger
        int uid = [defaults integerForKey:USERID_KEY];
        
        // if we have default data then fill-in login info
        //
        if ( username != nil && passwd != nil )
        {
            User *uinfo = [User Uinfo]; // GLOBAL user login info
            uinfo.userid = uid; // save userid
            uinfo.username = username; // save username
            
            _uname1.text = username;
            _passwd1.text = passwd;
            
            NSLog(@"defaults - userid: %d uname: %@ passwd: %@",uid,username,passwd);
        }
    }
    
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (IBAction)Login:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
//}
@end




@interface Auction : NSObject
{
    NSString *auc_id;
    NSString *pprice;
    UIImageView *pic;
    UIButton *blitz;
    UILabel *timer;
    UILabel *price;
    UILabel *uname;
    UILabel *binprice;
    UIButton *bidbutt;
}

-(NSString *) auc_id;
-(NSString *) pprice;
-(UIImageView *) pic;
-(UIButton *) blitz;
-(UILabel *)timer;
-(UILabel *)price;
-(UILabel *)uname;
-(UILabel *)binprice;
-(UIButton *)bidbutt;
-(void) setId:(NSString *) theId;
-(void) setTimer:(UILabel *) theTimer;
@end

@implementation Auction

-(NSString *) auc_id;
{
    return auc_id;
}

-(UILabel *) timer;
{
    return timer;
}

-(UIImageView *) pic;
{
    return pic;
}

-(UIButton *) blitz;
{
    return blitz;
}


-(NSString *) pprice;
{
    return pprice;
}

-(UIButton *) bidbutt;
{
    return bidbutt;
}
-(UILabel *) uname;
{
    return uname;
}

-(UILabel *) price;
{
    return price;
}

-(UILabel *) binprice;
{
    return binprice;
}

-(void) setId:(NSString *) theId
{
    auc_id = [[NSString alloc]initWithString: theId];
}

-(void) setPprice:(NSString *) thePrice
{
    pprice = [[NSString alloc]initWithString: thePrice];
}

-(void) setImage:(UIImageView *) theImg
{
    pic = theImg;
}

-(void) setBlitz:(UIButton *) theblitz
{
    blitz = theblitz;
}


-(void) setTimer:(UILabel *) theTimer;
{
    timer = theTimer;
}

-(void) setBidButt:(UIButton *) theButt;
{
    bidbutt = theButt;
}

-(void) setPrice:(UILabel *) thePrice;
{
    price = thePrice;
}

-(void) setBinPrice:(UILabel *) thePrice;
{
    binprice = thePrice;
}

-(void) setUname:(UILabel *) theUname;
{
    uname = theUname;
}

@end


@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIView *TopMenu;
@property (strong, nonatomic) IBOutlet UIScrollView *Scroller;
@property (strong, nonatomic) IBOutlet UIImageView *mainContainer;
@property (strong, nonatomic) IBOutlet UIView *MenuView;
@property (strong, nonatomic) AVAudioPlayer *PlayWinner;
@property (strong, nonatomic) AVAudioPlayer *PlayBid;
@property (strong, nonatomic) NSURLConnection *connUpdates;
@property (strong, nonatomic) NSURLConnection *connBP;
@property (strong, nonatomic) NSURLConnection *conn1;
@property (strong, nonatomic) NSURLConnection *conn2;

- (void) buildAuctions;
- (void)getUpdates;
- (IBAction)bidAction:(id)sender;
- (IBAction)binAction:(id)sender;
- (IBAction)blitzCB:(id)sender;
- (IBAction)hiwAction:(id)sender;

- (Auction *) findAuction:(NSString *) auc_id;



@end

@implementation ViewController

@synthesize PlayWinner;
@synthesize PlayBid;
@synthesize connBP;
@synthesize connUpdates;

//
// array of Auction objects containing window controls for each obj
//
NSMutableArray* aucobjs = nil;
NSArray* aucs = nil;
NSString* allAucs = @"";  // pipe seperated list of Auctions currently displayed
NSMutableData *reqData = nil;

//UIViewController *loginView = nil;

UIImage *homeSelected = nil;
UIImage *homeUnselected = nil;
UIImage *bnSelected = nil;
UIImage *bnUnselected = nil;
UIImage *winnersSelected = nil;
UIImage *winnersUnselected = nil;
UIImage *acctSelected = nil;
UIImage *acctUnselected = nil;
UIImage *bcSelected = nil;
UIImage *bcUnselected = nil;
UIImage *chatSelected = nil;
UIImage *chatUnselected = nil;
UIImage *pcbutt = nil;
UIImage *pcbutt_disabled = nil;
UIImage *freebutt = nil;
UIImage *sold = nil;
UIImage *blitz_logo = nil;
UIImage *credits_box = nil;
UIImage *bcredits_box = nil;
UIImage *pcredits_box = nil;

UISegmentedControl *menuctrl = nil;

bool firstGet = YES;

// BID BUTTON callback
//
- (IBAction)bidAction:(id)sender {
    
    User *uinfo = [User Uinfo]; // global login info
    
    NSLog(@"Button pressed: %@", [sender currentTitle]);
    
    
    // if user is not logged in then show the LOGIN/REGISTER screen
    //
    if ( uinfo == nil ||  uinfo.userid == 0 )
    {
        [uinfo.timer invalidate];
        uinfo.timer = nil;
        uinfo.updateDone = YES;
        
         UIStoryboard *storyboard = self.storyboard;
        
         LoginViewController *logView = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
        
        [self presentViewController: logView animated:YES completion:nil];        
        //[self performSegueWithIdentifier:@"LoginViewSEQ" sender:self];
        
    }
    else
    {
        NSURL *URL = [NSURL URLWithString: [NSString stringWithFormat:
                      @"http://192.168.0.196/bid_mobile.php?auc_id=%@",[sender currentTitle]]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        
        [NSURLConnection connectionWithRequest:request delegate:self];
        //connBP = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        //NSLog(@"Button pressed: %@", [sender currentTitle]);
    }
}
    
// BIN button callback
//
- (IBAction)binAction:(id)sender
{    
    User *uinfo = [User Uinfo]; // global login info
    
    // if user is not logged in then show the LOGIN/REGISTER screen
    //
    if ( uinfo == nil ||  uinfo.userid == 0 )
    {
        [uinfo.timer invalidate];
        uinfo.timer = nil;
        
        UIStoryboard *storyboard = self.storyboard;
        LoginViewController *logView = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
        
        [self presentViewController: logView animated:YES completion:nil];
    }
    else
    {
    }
    
    NSLog(@"BIN Button pressed: %@", [sender currentTitle]);
}

// BIN button callback
//
- (IBAction)blitzCB:(id)sender
{
    User *uinfo = [User Uinfo]; // global login info
    
    // if user is not logged in then show the LOGIN/REGISTER screen
    //
    if ( uinfo == nil ||  uinfo.userid == 0 )
    {
        [uinfo.timer invalidate];
        uinfo.timer = nil;
        
        UIStoryboard *storyboard = self.storyboard;
        LoginViewController *logView = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
        
        [self presentViewController: logView animated:YES completion:nil];
    }
    else
    {
    }
    
    NSLog(@"BLITZ Button pressed: %@", [sender currentTitle]);
}

- (IBAction)hiwAction:(id)sender
{
    NSLog(@"How It Works Button pressed");
}

- (Auction *)findAuction:(NSString *) auc_id
{
    int i = 0;
    int len = [aucobjs count];
    Auction *obj = nil;
    
    for ( i=0; i<len; i++ )
    {
        obj = (Auction *)[aucobjs objectAtIndex:i];
        
        if ( [obj.auc_id isEqualToString: auc_id] )return obj;
    }
    
    return (Auction *) nil;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    reqData = [[NSMutableData alloc] init];
    //[reqData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [reqData appendData:data];
    
    //NSLog(@"GOT DATA FRZOZM SERVER...");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    User *uinfo = [User Uinfo]; // GLOBAL login info
    
    uinfo.updateDone = YES;
    
    //[uinfo.connUpdates unregisterObject:self];
    //uinfo.connUpdates = nil;
    [reqData setLength:0];
    reqData = nil;
    //connection = nil;
    
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    
    NSLog(@"GOT ERROR FROM HTTP RESPONSE: %@",error);
    
    //[[NSAlert alertWithError:error] runModal];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Once this method is invoked, "responseData" contains the complete result
    User *uinfo = [User Uinfo]; // global login info
    
    NSString *str = [[NSString alloc] initWithData:reqData encoding:NSASCIIStringEncoding];
    
    
    //NSLog(@"server data: %@",str);
    
    int alen = [str length];
    
    //NSLog(@"got data from server - len: %d",alen);
    
    if ( alen < 2 )
    {
        [reqData setLength:0];
        reqData = nil;
        //connection = nil;
        
        uinfo.updateDone = YES;
        NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
        [NSURLCache setSharedURLCache:sharedCache];
        
        return;
    }
    
    NSLog(@"GOT DATA FROM SERVER...");
    
    NSArray* auc_dat = nil;
    NSArray* allaucs = [str componentsSeparatedByString: @"-|-"];
    
    int auc_type = 0;
    int free_lock = 0;
    int is_free = 0;
    int status = 0;
    int grabmax = 0;
    int grabusers = 0;
    int is_gguser = 0;
    int uid = 0;
    int total_fields = 0;
    int is_winner = 0;
    int do_bin = 0;
    int blitz = 0;
    int gps = 0;
    int bps = 0;
    int timeleft = 0;
    int seconds = 0;
    int minutes = 0;
    int hours = 0;
    int UID = 0;
    
    
    NSString* auc_id = nil;
    NSString* price = nil;
    NSString* binprice = nil;
    NSString* uname = nil;
    NSString* newimg = nil;
    NSString* stimeleft = nil;
    
    NSString *credits = nil;
    NSString *bcredits = nil;
    NSString *pcredits = nil;
    
    int i = 0;
    int auclen = [aucobjs count];
    Auction *obj = nil;
    Auction *aobj = nil;
    
    alen = [allaucs count];
    
    
    
    // if user is not logged in then show the LOGIN/REGISTER screen
    //
    if ( uinfo != nil && uinfo.userid != 0 )
    {
        UID = uinfo.userid;
    }
    
    for (NSString *auc in allaucs)
    {
        auc_dat = [auc componentsSeparatedByString: @"|"];
        
        total_fields = [auc_dat count];
        
        //NSLog(@"total fields in auc: %d",total_fields);
        
        if ( [auc_dat count] < 1 ) continue;
        
        auc_id = [auc_dat objectAtIndex: 1];
        
        obj = nil;
        
        for ( i=0; i<auclen; i++ )
        {
            aobj = (Auction *)[aucobjs objectAtIndex:i];
            
            if ( [aobj.auc_id isEqualToString: auc_id] ) obj = aobj;
        }
        
        if ( obj != nil )
        {
            //NSLog(@"auc: %@ not found!",auc_id);
        }
        
        // make sure this is an auction that's on our screen...
        //
        if ( obj != nil )
        {
            auc_type = [[auc_dat objectAtIndex: 0] intValue];
            free_lock = [[auc_dat objectAtIndex: 2] intValue];
            is_free = [[auc_dat objectAtIndex: 3] intValue];
            status = [[auc_dat objectAtIndex: 4] intValue];
            grabmax = [[auc_dat objectAtIndex: 5] intValue];
            grabusers = [[auc_dat objectAtIndex: 6] intValue];
            is_gguser = [[auc_dat objectAtIndex: 7] intValue];
            uid = [[auc_dat objectAtIndex: 8] intValue];
            price = [auc_dat objectAtIndex: 9];
            is_winner = [[auc_dat objectAtIndex: 10] intValue];
            do_bin = [[auc_dat objectAtIndex: 11] intValue];
            binprice = [auc_dat objectAtIndex: 12];
            uname = [auc_dat objectAtIndex: 13];
            newimg = [auc_dat objectAtIndex: 14];
            blitz = [[auc_dat objectAtIndex: 15] intValue];
            gps = [[auc_dat objectAtIndex: 16] intValue];
            bps = [[auc_dat objectAtIndex: 17] intValue];
            timeleft = [[auc_dat objectAtIndex: 18] intValue];
            
            if ( UID != 0 && total_fields > 19 )
            {
                credits = [auc_dat objectAtIndex: 19];
                bcredits = [auc_dat objectAtIndex: 20];
                pcredits = [auc_dat objectAtIndex: 21];
                
                dispatch_async(dispatch_get_main_queue(),^{
                    [uinfo.credits setText: credits];
                    [uinfo.bcredits setText: bcredits];
                });
                
                //NSLog(@"CREDITS: %@ BCREDITS: %@ PCREDITS: %@",credits,bcredits,pcredits);
            }
            
            seconds = timeleft % 60;
            minutes = (timeleft / 60) % 60;
            hours = timeleft / 3600;
            
            stimeleft = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
            
            //NSLog(@"got data from server auc data: %@  auc type: %d time: %d",auc,auc_type,timeleft);
            
            if ( auc_type == 0 ) [obj.timer setText: stimeleft];
            
            if ( blitz == 1 )
            {
                
                dispatch_async(dispatch_get_main_queue(),^{
                    //pr = [[UILabel alloc] initWithFrame:CGRectMake(10, 130, 60, 12)];
                    //pr = [[UILabel alloc] initWithFrame:CGRectMake(30, 130, 60, 12)];
                    
                    obj.price.frame = CGRectMake(10,130,60,12);
                    [obj.pic addSubview:obj.blitz];
                    [obj.blitz setHidden:NO];
                });
                
            }
            else
            {
                
                dispatch_async(dispatch_get_main_queue(),^{
                    //pr = [[UILabel alloc] initWithFrame:CGRectMake(10, 130, 60, 12)];
                    //pr = [[UILabel alloc] initWithFrame:CGRectMake(30, 130, 60, 12)];
                    [obj.blitz setHidden:YES];
                    obj.price.frame = CGRectMake(30,130,60,12);
                    
                });
                
            }
            //
            // update UI price,BIN price, name on main thread...
            //
            
            dispatch_async(dispatch_get_main_queue(),^{
                [obj.price setText: [NSString stringWithFormat:@"$%@",price]];
                [obj.uname setText: uname];
                [obj.binprice setText: [NSString stringWithFormat:@"$%@",binprice]];
            });
            
            if ( is_winner == 1 )
            {
                
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    [PlayWinner play];
                });
                
                //
                // show animation on main thread...
                //
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    UIImageView *pic = [[UIImageView alloc] initWithFrame:CGRectMake(9, 28, 100, 60)];
                    
                    [pic setBackgroundColor:[UIColor clearColor]];
                    
                    [pic setImage: sold];
                    [obj.pic addSubview:pic];
                    
                    [obj.bidbutt setHidden:YES];
                    
                    UIImageView *lockImage = obj.pic;
                    
                    CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"position"];
                    [shake setDuration:0.1];
                    [shake setRepeatCount:4];
                    [shake setAutoreverses:YES];
                    [shake setFromValue:[NSValue valueWithCGPoint:
                                         CGPointMake(lockImage.center.x - 5,lockImage.center.y)]];
                    [shake setToValue:[NSValue valueWithCGPoint:
                                       CGPointMake(lockImage.center.x + 5, lockImage.center.y)]];
                    [lockImage.layer addAnimation:shake forKey:@"position"];
                    
                });
                
            }
            
            if ( free_lock != 0 )
            {
                //
                // show disabled bid button on main thread...
                //
                
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    [obj.bidbutt setBackgroundImage: pcbutt_disabled
                                           forState:UIControlStateNormal];
                });
                
            }
            else
            {
                //
                // show normal bid button on main thread...
                //
                
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    if ( is_free == 1 )
                    {
                        [obj.bidbutt setBackgroundImage: freebutt
                                               forState:UIControlStateNormal];
                    }
                    else
                    {
                        [obj.bidbutt setBackgroundImage: pcbutt
                                           forState:UIControlStateNormal];
                    }
                });
                
            }
            
            //NSLog(@"old price: %@ new price: %@",obj.pprice,price );
            
            // highlight the price background on bid change
            //
            if ( ![obj.pprice isEqualToString: price] )
            {
                
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    [PlayBid play];
                });
                
                //NSLog(@"setting highlite on: %@",obj.auc_id );
                
                [obj setPprice: price]; // keep track of the new price
                
                //[UIColor colorWithRed:(1/255.f) green:(149/255.f) blue:(212/255.f) alpha:1.0f]
                
                // wait 150,000th of a second and then reset the price background
                // (done  in asynch queue on the main thread)
                //
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                               ^{
                                   [obj.price setBackgroundColor:[UIColor yellowColor]];
                                   
                                   usleep(150000);
                                   
                                   dispatch_async(dispatch_get_main_queue(),
                                                  ^{
                                                      [obj.price setBackgroundColor:[UIColor clearColor]];
                                                      NSLog(@"clearing highlite on: %@",obj.auc_id );
                                                  });
                               });
                
            }
        }
        
        //
    }
    
    [reqData setLength:0];
    reqData = nil;
    //connection = nil;
    //uinfo.connUpdates = nil;
    uinfo.updateDone = YES;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    
    //baseURL = [[request URL] retain];
    return request;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

-(void) getUpdates
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    User *uinfo = [User Uinfo]; // GLOBAL login info
 
    if ( !uinfo.updateDone )
    {
        return;
    }
    
    uinfo.updateDone = NO;
    
    //if ( uinfo != nil &&  uinfo.userid != 0 )
    //NSLog(@"user id: %d - username: %@",uinfo.userid,uinfo.username);
    
    NSURL *URL =  nil;   //int objlen = [aucobjs count];
    
    if ( firstGet || uinfo.force_reload == nil)
        URL = [NSURL URLWithString: @"http://192.168.0.196/auc_info_mobile.php?force_update=1"];
    else
        URL = [NSURL URLWithString: @"http://192.168.0.196/auc_info_mobile.php"];
    
    firstGet = NO;
    uinfo.force_reload = @"0";
    
    //reqData = [NSMutableData data];
    
    //baseURL = [[NSURL URLWithString:@"http://store.apple.com"] retain];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    [NSURLConnection connectionWithRequest:request delegate:self];
    //uinfo.connUpdates = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

// CREATE AUCTIONS FROM SERVER DATA
//
- (void) buildAuctions
{
    //BOOL bfirst = true;
    NSString *cmd = nil;
    NSString *aid = nil;
    NSString *desc = nil;
    NSString *srange = nil;
    NSString *erange = nil;
    NSString *xpic = nil;
    NSString *xprice = nil;
    NSString *auc_type = nil;
    NSString *dobin = nil;
    NSString *binprice = nil;
    NSString *xusr = @"";
    NSString *xblitz = nil;
    NSString *xis_free = nil;
    NSString *xprizes = nil;
    
    UIImageView *image = nil;
    UILabel *lab = nil;
    UILabel *dp = nil;
    UILabel *pr = nil;
    UILabel *ur = nil;
    UILabel *tim = nil;
    UILabel *binlab = nil;
    UIButton *btn = nil;
    UIButton *binbtn = nil;
    UIImageView *pic = nil;
    UIButton *blitzbtn = nil;
    NSString *URL = nil;
    UIImage *pImage = nil;
    NSString *fimg = @"http://192.168.0.196/prodImages/";
    NSString *range = nil;
    NSString *price = nil;
    
    int len = [aucs count];
    int x = 10;
    
    if ( len == 0 ) return;
    
    for (NSDictionary *obj in aucs)
    {
        //obj = [aucs objectAtIndex:i];
        cmd = [obj valueForKey:@"cmd"];
        
        if ( [cmd isEqualToString: @"1"] || [cmd isEqualToString: @"2"] )
        {
            Auction *auc = [Auction alloc]; // create global auction object to save "updateable" controls
            
            aid = [obj valueForKey:@"aid"];
            desc = [obj valueForKey:@"pdesc"];
            xpic = [obj valueForKey:@"pic"];
            srange = [obj valueForKey:@"start_range"];
            erange = [obj valueForKey:@"end_range"];
            xprice = [obj valueForKey:@"price"];
            dobin = [obj valueForKey:@"dobin"];
            binprice = [obj valueForKey:@"buynow"];
            auc_type = [obj valueForKey:@"auc_type"];
            xblitz= [obj valueForKey:@"blitz"];
            xis_free = [obj valueForKey:@"is_free"];            
            xprizes = [obj valueForKey:@"prizes"];
            
            
            [auc setId: aid]; // save the auction ID
            
            //NSLog(@"auc: %@\ndesc: %@",aid,desc);
            
            image = [[UIImageView alloc] initWithFrame:CGRectMake(x+0, 5, 118, 200)];
            
            if ( [xis_free isEqualToString: @"1"] || [xis_free isEqualToString: @"5"] )
            {
                [image setImage:[UIImage imageNamed:[NSString stringWithFormat:@"bg-free-118x200.png"]]];
            }
            else if ( [xprizes isEqualToString: @"2"] )
            {
                [image setImage:[UIImage imageNamed:[NSString stringWithFormat:@"bg-mystery-118x200.png"]]];
            }
            else
            {
                [image setImage:[UIImage imageNamed:[NSString stringWithFormat:@"bg-normal-118x200.png"]]];
            }
            
            
            lab = [[UILabel alloc] initWithFrame:CGRectMake(2, 1, 110, 25)];
            lab.font = [UIFont fontWithName:@"AvenirNext-Bold" size:10];
            [lab setText: desc];
            [lab setTextColor: [UIColor whiteColor]];
            [lab setBackgroundColor:[UIColor clearColor]];            
            lab.lineBreakMode = NSLineBreakByWordWrapping;
            lab.numberOfLines = 0;
            lab.textAlignment = NSTextAlignmentCenter;
            
            pic = [[UIImageView alloc] initWithFrame:CGRectMake(9, 28, 100, 60)];
            
            URL = [NSString stringWithFormat:@"%@%@",fimg,xpic];
            
            pImage=[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:URL]]];
            
            [pic setImage:pImage];
 
            [auc setImage: image]; // save the main image obj
            
            if ( [auc_type isEqualToString: @"1"] )
            {
                range = [NSString stringWithFormat:@"Deal Price is Between $%@ - $%@",srange,erange];
            
                dp = [[UILabel alloc] initWithFrame:CGRectMake(2, 92, 110, 25)];
                dp.font = [UIFont fontWithName:@"AvenirNext-Bold" size:10];
                [dp setText: range];
                [dp setTextColor: [UIColor darkGrayColor]];
                [dp setBackgroundColor:[UIColor clearColor]];
                dp.lineBreakMode = NSLineBreakByWordWrapping;
                dp.numberOfLines = 0;
                dp.textAlignment = NSTextAlignmentCenter;
            }
            else
            {
                tim = [[UILabel alloc] initWithFrame:CGRectMake(5, 96, 110, 25)];
                tim.font = [UIFont fontWithName:@"AvenirNext-Bold" size:20];
                [tim setText: @"10:59:59"];
                [tim setTextColor: [UIColor blackColor]];
                [tim setBackgroundColor:[UIColor clearColor]];
                tim.lineBreakMode = NSLineBreakByWordWrapping;
                tim.numberOfLines = 0;
                tim.textAlignment = NSTextAlignmentCenter;
                
                [auc setTimer: tim]; // save the timer label
            }
            
            price = [NSString stringWithFormat:@"$%@",xprice];
            
            if ( [xblitz isEqualToString: @"1"] )
            {
                pr = [[UILabel alloc] initWithFrame:CGRectMake(10, 130, 60, 12)];
                
                pr.font = [UIFont fontWithName:@"AvenirNext-Bold" size:12];
                [pr setText: price];
                [pr setTextColor:[UIColor colorWithRed:(1/255.f) green:(149/255.f) blue:(212/255.f) alpha:1.0f]];
                [pr setBackgroundColor:[UIColor clearColor]];
                pr.lineBreakMode = NSLineBreakByWordWrapping;
                pr.numberOfLines = 0;
                pr.textAlignment = NSTextAlignmentCenter;
            }
            else
            {
                pr = [[UILabel alloc] initWithFrame:CGRectMake(30, 130, 60, 12)];
                pr.font = [UIFont fontWithName:@"AvenirNext-Bold" size:12];
                [pr setText: price];
                [pr setTextColor:[UIColor colorWithRed:(1/255.f) green:(149/255.f) blue:(212/255.f) alpha:1.0f]];
                [pr setBackgroundColor:[UIColor clearColor]];
                pr.lineBreakMode = NSLineBreakByWordWrapping;
                pr.numberOfLines = 0;
                pr.textAlignment = NSTextAlignmentCenter;
            }
            
            blitzbtn = [[UIButton alloc] initWithFrame:CGRectMake(75, 123, 34, 22)];
            
            [blitzbtn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal  ];
            [blitzbtn setTitle:aid forState:UIControlStateNormal];
            
            [blitzbtn setBackgroundImage: blitz_logo  
                           forState:UIControlStateNormal];
            
            [blitzbtn addTarget:self action:@selector(blitzCB:) forControlEvents:UIControlEventTouchUpInside];
            
            [auc setBlitz: blitzbtn]; // save the price label            }
                
            [auc setPrice: pr]; // save the price label
            [auc setPprice: xprice]; // save the current price
            
            ur = [[UILabel alloc] initWithFrame:CGRectMake(5, 145, 110, 12)];
            ur.font = [UIFont fontWithName:@"EuphemiaUCAS-Bold" size:12];
            [ur setText: xusr];
            [ur setTextColor:[UIColor blackColor]];
            [ur setBackgroundColor:[UIColor clearColor]];
            ur.lineBreakMode = NSLineBreakByWordWrapping;
            ur.numberOfLines = 0;
            ur.textAlignment = NSTextAlignmentCenter;
            
            [auc setUname: ur]; // save the username label
           
            
            if ( [xis_free isEqualToString: @"1"] || [xis_free isEqualToString: @"5"] )
            {
                btn = [[UIButton alloc] initWithFrame:CGRectMake(7, 170, 60, 25)];
                
                [btn setBackgroundImage: pcbutt
                               forState:UIControlStateNormal];            }
            else
            {
                btn = [[UIButton alloc] initWithFrame:CGRectMake(7, 170, 50, 25)];
            
                [btn setBackgroundImage: pcbutt
                                forState:UIControlStateNormal];
            }
            
            [btn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal  ];
            [btn setTitle:aid forState:UIControlStateNormal];
            
            [btn addTarget:self action:@selector(bidAction:) forControlEvents:UIControlEventTouchDown];
            
            [auc setBidButt: btn]; // save the bid button
            
            image.userInteractionEnabled = YES; // turn on interactions so the buttons can get events
            
                
            if ( [dobin isEqualToString: @"1"] )
            {
                binbtn = [[UIButton alloc] initWithFrame:CGRectMake(62, 170, 50, 25)];
                [binbtn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal  ];
                
                [binbtn setTitle:aid forState:UIControlStateNormal];

                [binbtn setBackgroundImage:[UIImage imageNamed:@"bnbutt.png"]
                               forState:UIControlStateNormal];
                
                [binbtn addTarget:self action:@selector(binAction:) forControlEvents:UIControlEventTouchUpInside];
                
                binlab = [[UILabel alloc] initWithFrame:CGRectMake(2, 12, 48, 12)];
                binlab.font = [UIFont fontWithName:@"AvenirNextCondensed-Bold" size:10];
                [binlab setText: binprice];
                [binlab setTextColor:[UIColor whiteColor]];
                [binlab setBackgroundColor:[UIColor clearColor]];
                binlab.lineBreakMode = NSLineBreakByWordWrapping;
                binlab.numberOfLines = 1;
                binlab.textAlignment = NSTextAlignmentCenter;
                
                [auc setBinPrice: binlab]; // save the BIN label
            }
            
            
            [image addSubview:lab];
            [image addSubview:pic];

            if ( [auc_type isEqualToString: @"1"] )
            {
                [image addSubview:dp];
            }
            else
            {
                [image addSubview:tim];
            }
        
            if ( [xblitz isEqualToString: @"1"] )
            {
                [image addSubview:blitzbtn];
            }
            
            [image addSubview:pr];
            [image addSubview:ur];
            [image addSubview:btn];
 
            if ( [dobin isEqualToString: @"1"] )
            {
                [image addSubview:binbtn];
                [binbtn addSubview:binlab];
            }
            
            [_Scroller addSubview:image];
            
            x+=130;
            
            [aucobjs addObject:auc]; // add the saved info to the list
        }
    }
    
    _Scroller.contentSize = CGSizeMake(x, 0);

    //NSLog(@"got all aucs: %@",allAucs);
 
    // get auction updates every sec
    //
    User *uinfo = [User Uinfo]; // GLOBAL user login info
    
    uinfo.timer = [NSTimer scheduledTimerWithTimeInterval:.65 target:self selector:@selector(getUpdates) userInfo:nil repeats:YES];

}


-(void) UpdateAuctions
{
    NSURL *auctionURL = [NSURL URLWithString: [NSString stringWithFormat:
                                            @"http://192.168.0.196/auc_updates.php?aucStr=%@",allAucs]];
    
    dispatch_queue_t AuctionQueue = dispatch_queue_create("com.pg.auction", 0);
    
    dispatch_async(AuctionQueue,
                   ^{NSData* data = [NSData dataWithContentsOfURL: auctionURL];
                       [self performSelectorOnMainThread:@selector(fetchAuctionData:) withObject:
                        data waitUntilDone:YES];
                   });
}

- (IBAction)MainMenu:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    
    switch(segmentedControl.selectedSegmentIndex)
    {
        case 0:
             break;
        case 1:
            break;
        case 2:
             break;
    }
    
    NSLog(@"index changed: %d",selectedSegment);
}


- (void)viewDidLoad
{
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    User *uinfo = [User Uinfo]; // GLOBAL user login info
    
    uinfo.mainView = self;
    
    //AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    //NSError *setCategoryError = nil;
    //BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    //if (!success) { NSLog(@"ERROR activating audio session category!"); }
    
    //NSError *activationError = nil;
    //success = [audioSession setActive:YES error:&activationError];
    //if (!success) { NSLog(@"ERROR activating audio session!"); }
    
    
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
    
    if (!success) { NSLog(@"ERROR activating audio session/category!"); }
    
    
    UInt32 doSetProperty = true;
    
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
    
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
    NSURL *winnerURL = [[NSBundle mainBundle]
                    URLForResource: @"winner" withExtension:@"mp3"];
    
    NSURL *bidURL = [[NSBundle mainBundle]
                        URLForResource: @"bid" withExtension:@"mp3"];
    
    NSError *err = nil;
    
    PlayWinner = [[AVAudioPlayer alloc] initWithContentsOfURL:winnerURL error:&err];
    PlayBid = [[AVAudioPlayer alloc] initWithContentsOfURL:bidURL error:&err];
    
    
    success = [PlayWinner prepareToPlay];
    if (!success)
    {
        NSLog(@"ERROR preparing audio to play: %@",err);
    }
    
    success = [PlayBid prepareToPlay];
    if (!success)
    {
        NSLog(@"ERROR preparing audio to play: %@",err);
    }
    
    
    aucobjs = [[NSMutableArray alloc] init];
    
    NSURL *auctionURL = [NSURL URLWithString: @"http://192.168.0.196/auc_updates_mobile.php"];
    
    dispatch_queue_t AuctionQueue = dispatch_queue_create("com.pg.auction", 0);
    
    dispatch_async(AuctionQueue,
                   ^{NSData* data = [NSData dataWithContentsOfURL: auctionURL];
                       [self performSelectorOnMainThread:@selector(fetchAuctionData:) withObject:
                        data waitUntilDone:YES];
                   });
    
    homeSelected = [[UIImage imageNamed:@"xhome.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    homeUnselected = [[UIImage imageNamed:@"xhome-off.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    bcSelected = [[UIImage imageNamed:@"xbuycredits.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    bcUnselected = [[UIImage imageNamed:@"xbuycredits-off.png" ]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) ];
    
    bnSelected = [[UIImage imageNamed:@"xbuynow.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    bnUnselected = [[UIImage imageNamed:@"xbuynow-off.png" ]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) ];
    
    winnersSelected = [[UIImage imageNamed:@"xwinners.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    winnersUnselected = [[UIImage imageNamed:@"xwinners-off.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    acctSelected = [[UIImage imageNamed:@"xmyacct.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    acctUnselected = [[UIImage imageNamed:@"xmyacct-off.png" ]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) ];
    chatSelected = [[UIImage imageNamed:@"xchat.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    chatUnselected = [[UIImage imageNamed:@"xchat-off.png" ]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) ];
    
    pcbutt = [[UIImage imageNamed:@"pcbutt.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    pcbutt_disabled = [[UIImage imageNamed:@"pcbutt_disabled.png" ]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) ];
    
    freebutt = [[UIImage imageNamed:@"FreeGrabButton.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    sold = [[UIImage imageNamed:@"sold.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    blitz_logo = [[UIImage imageNamed:@"blitz_logo.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    credits_box = [[UIImage imageNamed:@"credits-box.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];    
    bcredits_box = [[UIImage imageNamed:@"bcredits-box.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    pcredits_box = [[UIImage imageNamed:@"pcredits-box.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    UIImage *hiw = [[UIImage imageNamed:@"howitworks.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    UISegmentedControl *menuctrl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", nil]];
    
    menuctrl.frame = CGRectMake(0,0,10,10);
    
    menuctrl.segmentedControlStyle = UISegmentedControlStyleBar;
    menuctrl.contentMode = UIViewContentModeScaleToFill;
    
    //CGRect frame = menuctrl.frame;
    
    //[menuctrl setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 50)];
    
    
    [menuctrl setWidth: 80 forSegmentAtIndex: 0];
    [menuctrl setWidth: 80 forSegmentAtIndex: 1];
    [menuctrl setWidth: 80 forSegmentAtIndex: 2];
    [menuctrl setWidth: 80 forSegmentAtIndex: 3];
    [menuctrl setWidth: 80 forSegmentAtIndex: 4];
    [menuctrl setWidth: 80 forSegmentAtIndex: 5];
/*
    [menuctrl setDividerImage:[dividerImageForLeftSegmentState:[rightSegmentState:barMetrics:] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:segmentSelectedUnselected forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:segUnselectedSelected forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
 */
    
    CGSize off;
    off.width = 0;
    off.height = -5;

    [menuctrl setContentOffset: off forSegmentAtIndex: 0];
    [menuctrl setContentOffset: off forSegmentAtIndex: 1];
    [menuctrl setContentOffset: off forSegmentAtIndex: 2];
    [menuctrl setContentOffset: off forSegmentAtIndex: 3];
    [menuctrl setContentOffset: off forSegmentAtIndex: 4];
    [menuctrl setContentOffset: off forSegmentAtIndex: 5];
    
    
    //[menuctrl contentMode: 80 forSegmentAtIndex: 0];
    //[resizeableImageWithCapInsets: resizingMode: UIImageResizingModeStretch];
    
    [menuctrl setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
     
    menuctrl.translatesAutoresizingMaskIntoConstraints = YES;
  
    
    [menuctrl addTarget:self action:@selector(MainMenu:) forControlEvents:UIControlEventValueChanged];
    
    [menuctrl setImage:homeSelected forSegmentAtIndex:0];
    [menuctrl setImage:bcUnselected forSegmentAtIndex:1];
    [menuctrl setImage:winnersUnselected forSegmentAtIndex:2];
    [menuctrl setImage:bnUnselected forSegmentAtIndex:3];
    [menuctrl setImage:acctUnselected forSegmentAtIndex:4];
    [menuctrl setImage:chatUnselected forSegmentAtIndex:5];

    UIImageView *image1 = [[UIImageView alloc] initWithFrame:CGRectMake(140, 3, 115, 38)];
    [image1 setImage: credits_box];
    
    UILabel *lab1 = [[UILabel alloc] initWithFrame:CGRectMake(75, 15, 40, 12)];
    lab1.font = [UIFont fontWithName:@"AvenirNext-Bold" size:11];
    [lab1 setText: @"0"];
    [lab1 setTextColor: [UIColor whiteColor]];
    [lab1 setBackgroundColor:[UIColor clearColor]];
    lab1.lineBreakMode = NSLineBreakByWordWrapping;
    lab1.numberOfLines = 0;
    lab1.textAlignment = NSTextAlignmentCenter;
    
    UIImageView *image2 = [[UIImageView alloc] initWithFrame:CGRectMake(255, 3, 117, 38)];
    [image2 setImage: bcredits_box];
    
    UILabel *lab2 = [[UILabel alloc] initWithFrame:CGRectMake(75, 15, 40, 12)];
    lab2.font = [UIFont fontWithName:@"AvenirNext-Bold" size:12];
    [lab2 setText: @"0"];
    [lab2 setTextColor: [UIColor whiteColor]];
    [lab2 setBackgroundColor:[UIColor clearColor]];
    lab2.lineBreakMode = NSLineBreakByWordWrapping;
    lab2.numberOfLines = 0;
    lab2.textAlignment = NSTextAlignmentCenter;
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(385, 3, 89, 38)];
    
    [btn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal  ];
    
    [btn setBackgroundImage: hiw
                   forState:UIControlStateNormal];
    
    [btn addTarget:self action:@selector(hiwAction:) forControlEvents:UIControlEventTouchUpInside];
    uinfo.credits = lab1;
    uinfo.bcredits = lab2;
    
    [image1 addSubview: lab1];
    [image2 addSubview: lab2];
    
    [_MenuView addSubview:menuctrl];
    [_TopMenu addSubview: image1];
    [_TopMenu addSubview: image2];
    [_TopMenu addSubview: btn];
    
    dispatch_async(dispatch_get_main_queue(),^{
        menuctrl.selectedSegmentIndex = 0;
        NSLog(@"SCREEN WIDTH: %f",[UIScreen mainScreen].applicationFrame.size.width);
        NSLog(@"SCREEN HEIGHT: %f",[UIScreen mainScreen].applicationFrame.size.height);
        
        CGRect frame = menuctrl.frame;
        
        NSLog(@"menu height: %f",frame.size.height);
        
    });
}

- (void) fetchAuctionData:(NSData *) dat
{
    NSError* err;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:dat
                          options:NSJSONReadingAllowFragments
                          error: &err];
    
    aucs = [json valueForKey:@"auc"];
    
    //NSArray *aucs = [json valueForKey:@"aid"];
    
    //NSString *result = [json objectForKey:@"result"];
    //NSString* OK = @"Y";
    //NSString* BAD = @"N";
    
    // UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"JSON Message"
    // message:[NSString stringWithFormat:@"GOT %d auctions!",[aucs count]]
    // delegate:nil
    // cancelButtonTitle:@"OK"
    // otherButtonTitles:nil];
        
    // [alert show];
    
    //for(NSString * myStr in aucs) {
     //   NSLog(@"auc: %@",myStr);
    //}
    
    BOOL bfirst = true;
    NSString *cmd = nil;
    NSString *aid = nil;

    int len = [aucs count];

    if ( len == 0 ) return;
    
    for (NSDictionary *obj in aucs)
    {
        //obj = [aucs objectAtIndex:i];
        cmd = [obj valueForKey:@"cmd"];

        if ( [cmd isEqualToString: @"1"] || [cmd isEqualToString: @"2"] )
        {
          aid = [obj valueForKey:@"aid"];
                        
          if ( bfirst == false ) { allAucs = [NSString stringWithFormat:@"%@|",allAucs]; }
        
          bfirst = false;
        
          allAucs = [NSString stringWithFormat:@"%@%@",allAucs,aid];
        }
    }
    
    [self buildAuctions];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"*** MEMORY LOW! ***");
}

@end
