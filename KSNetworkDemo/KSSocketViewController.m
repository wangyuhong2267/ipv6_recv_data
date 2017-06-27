//
//  KSSocketViewController.m
//  KSNetworkDemo
//
//  Created by kesalin on 13/4/13.
//  Copyright (c) 2013 kesalin@gmail.com. All rights reserved.
//

#import "KSSocketViewController.h"
#import <arpa/inet.h>
#import <netdb.h>

// See http://www.telnet.org/htm/places.htm
//
#define kTestHost @"telnet://towel.blinkenlights.nl"
#define kTestPort 7890

@interface KSSocketViewController ()

@end

@implementation KSSocketViewController

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
    
    self.title = @"BSD Socket";
    
    self.serverAddressTextField.delegate = self;
    self.serverPortTextField.delegate = self;
    
    self.serverAddressTextField.text = kTestHost;
    self.serverPortTextField.text = [[NSNumber numberWithInt:kTestPort] stringValue];
    self.receiveTextView.text = @"";
    self.receiveTextView.editable = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL didResign = [textField resignFirstResponder];
    return didResign;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:@"Dismiss"
                                           otherButtonTitles:nil];
    [alert show];
}

- (IBAction)connectButtonClick:(id)sender
{
    NSString * serverHost = self.serverAddressTextField.text;
    NSString * serverPort = self.serverPortTextField.text;
    
    if (serverHost == nil || [serverHost isEqualToString:@""]) {
        [self showAlertWithTitle:@"Error" message:@"Server address cann't be empty!"];
        return;
    }
    
    if (serverPort == nil || [serverPort isEqualToString:@""]) {
        [self showAlertWithTitle:@"Error" message:@"Server port cann't be empty!"];
        return;
    }
    
    self.connectButton.enabled = NO;
    self.receiveTextView.text = @"Connecting to server...";
    [self.networkActivityView startAnimating];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@", serverHost, serverPort]];
    NSThread * backgroundThread = [[NSThread alloc] initWithTarget:self
                                                          selector:@selector(loadDataFromServerWithURL:)
                                                            object:url];
	[backgroundThread start];
}

- (void)networkFailedWithErrorMessage:(NSString *)message
{
    // Update UI
    //
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSLog(@" >> %@", message);

        self.receiveTextView.text = message;
        self.connectButton.enabled = YES;
        [self.networkActivityView stopAnimating];
    }];
}

- (void)networkSucceedWithData:(NSData *)data
{
    // Update UI
    //
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString * resultsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@" >> Received string: '%@'", resultsString);
        
        self.receiveTextView.text = resultsString;
        self.connectButton.enabled = YES;
        [self.networkActivityView stopAnimating];
    }];
}

#pragma mark -
#pragma mark Socket

- (void)loadDataFromServerWithURL:(NSURL *)url
{
    NSString * host = [url host];
    NSNumber * port = [url port];
    
    // Create socket
    //
//    int socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
//    if (-1 == socketFileDescriptor) {
//        NSLog(@"Failed to create socket.");
//        return;
//    }
//    
//    // Get IP address from host
//    //
//    struct hostent * remoteHostEnt = gethostbyname([host UTF8String]);
//    if (NULL == remoteHostEnt) {
//        close(socketFileDescriptor);
//        
//        [self networkFailedWithErrorMessage:@"Unable to resolve the hostname of the warehouse server."];
//        return;
//    }
//    
//    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
	
    // Set the socket parameters
    //
//	struct sockaddr_in socketParameters;
//	socketParameters.sin_family = AF_INET;
//	//socketParameters.sin_addr = *remoteInAddr;
//	socketParameters.sin_addr.s_addr = inet_addr("122.152.205.226");
//	socketParameters.sin_port = htons([port intValue]);
	
	struct addrinfo hints, *res, *res0;
	int error, s;
	const char *cause = NULL;
	const char *address = "64:ff9b::122.152.205.226";
	
	
	memset(&hints, 0, sizeof(hints));
	hints.ai_family = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags = AI_DEFAULT;
	error = getaddrinfo(address, NULL, &hints, &res0);
	if (error)
	{
		errx(1, "%s", gai_strerror(error));
	 
	}
	s = -1;
	
	for (res = res0; res; res = res->ai_next)
	{
		s = socket(res->ai_family,
				   res->ai_socktype,
				   res->ai_protocol);
		if (s < 0)
		{
			cause = "socket";
			continue;
		}
		
		struct sockaddr *addr;
		addr = (struct sockaddr *)res->ai_addr;
		struct sockaddr_in6 *v6sa = (struct sockaddr_in6 *)addr;
		v6sa->sin6_port = htons([port intValue]);

		NSLog(@"AF_INET6......");
		char ipv6_str_buf[INET6_ADDRSTRLEN] = { 0 };
		struct sockaddr_in6 *v6sa2 = (struct sockaddr_in6 *)addr;
		inet_ntop(AF_INET6, &(v6sa2->sin6_addr),
				  ipv6_str_buf, sizeof(ipv6_str_buf));
		NSString *ipString = [[NSString alloc] initWithCString:ipv6_str_buf encoding:NSUTF8StringEncoding];
		
		NSLog(@"Try connecting : %@", ipString);
		
		if (connect(s, res->ai_addr, res->ai_addrlen) < 0)
		{
			cause = "connect";
			close(s);
			s = -1;
			continue;
		}
		else{
			NSLog(@"connected......");
		}
		
		break;
	}
	int socketFileDescriptor = s;
    // Connect the socket
    //
//    int ret = connect(socketFileDescriptor, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
//	if (-1 == ret) {
//		close(socketFileDescriptor);
//		
//        NSString * errorInfo = [NSString stringWithFormat:@" >> Failed to connect to %@:%@", host, port];
//        [self networkFailedWithErrorMessage:errorInfo];
//		return;
//	}
	
    NSLog(@" >> aaa Successfully connected to %@:%@", host, port);

    NSMutableData * data = [[NSMutableData alloc] init];
	BOOL waitingForData = YES;
	
	// Continually receive data until we reach the end of the data
    //
    int maxCount = 5;   // just for test.
    int i = 0;
	while (waitingForData && i < maxCount) {
		const char * buffer[1024];
		int length = sizeof(buffer);
		
		// Read a buffer's amount of data from the socket; the number of bytes read is returned
        //
		int result = recv(socketFileDescriptor, &buffer, length, 0);
		NSLog(@"result=%d",result);
		if (result > 0) {
			//[data appendBytes:buffer length:result];
			char buf_temp[1024];
			memset(buf_temp,0,sizeof(buf_temp));
			memcpy(buf_temp,buffer,70);
			NSLog(@"buf_temp=%s",buf_temp);
		}
        else {
            // if we didn't get any data, stop the receive loop
            //
			waitingForData = NO;
		}
        
        ++i;
	}
	
	// Close the socket
    //
	close(socketFileDescriptor);
    
    [self networkSucceedWithData:data];
}

@end
