//
//  AuthenticationManager.m
//  iOS-login-boilerplate
//
//  Created by michael whitehead on 9/24/13.
//  Copyright (c) 2013 michael whitehead. All rights reserved.
//

#import "AuthenticationManager.h"
#import "NetCommunicator.h"
#import "AuthenticationManagerDelegate.h"

//figure out how to send post get or update with nsurl

@implementation AuthenticationManager

@synthesize receivedData;
@synthesize currentSelector;
@synthesize delegate;

- (NetCommunicator *)netCommunicatorCreator {
    NetCommunicator *netCommunicator = [[NetCommunicator alloc] init];
    netCommunicator.delegate = self;
    return netCommunicator;
}

- (void)createNewUserWithName:(NSString *)name email:(NSString *)email password:(NSString *)password {
    NSURL *fetchURL = [NSURL URLWithString:
                       [NSString stringWithFormat:@"%@/%@?name=%@&email=%@&password=%@",SERVER_URL,USERS_ROUTE,name, email,password]];
    [[self netCommunicatorCreator] fetchDataFromURL:fetchURL httpMethod:@"POST" params:nil];

}

- (void)fetchSessionWithEmail:(NSString *)email password:(NSString *)password {
    NSURL *fetchURL = [NSURL URLWithString:
                       [NSString stringWithFormat:@"%@/%@?email=%@&password=%@",SERVER_URL,LOGIN_ROUTE,email,password]];
    [[self netCommunicatorCreator] fetchDataFromURL:fetchURL httpMethod:@"POST" params:nil];
}

- (void)getResetCodeWithEmail:(NSString *)email {
    NSURL *fetchURL = [NSURL URLWithString:
                       [NSString stringWithFormat:@"%@/%@?email=%@", SERVER_URL, PASSWORD_ROUTE, email]];
    [[self netCommunicatorCreator] fetchDataFromURL:fetchURL httpMethod:@"GET" params:nil];
}


- (void)resetPasswordWithCode:(NSString *)code email:(NSString *)email password:(NSString *)password {
    NSURL *fetchURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?code=%@&email=%@&password=%@",SERVER_URL, PASSWORD_ROUTE, code, email, password]];
    [[self netCommunicatorCreator]fetchDataFromURL:fetchURL httpMethod:@"PUT" params:nil];
    
}

- (void)fetchingDataFailed:(NSError *)error {
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"Network connection failed. Please check network connection.", @"printableError", nil];
    NSError *newError = [[NSError alloc] initWithDomain:@"com.custom.domain" code:500 userInfo:userInfo];
    [delegate fetchingDataFailedWithError:newError];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)fetchingDataSucceeded:(NSData *)data {
    receivedData = data;
    [self performSelector:currentSelector withObject:data];
}
#pragma clang diagnostic pop

- (void)sessionWasFetched:(NSData *)data {
    NSError *error = nil;
    NSDictionary *deserialisedSession = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        NSDictionary *newUserInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"Unable to parse server response. Please do something!", @"printableError", nil];
        NSError *newError = [[NSError alloc] initWithDomain:@"com.custom.domain" code:500 userInfo:newUserInfo];
        [delegate fetchingDataFailedWithError:newError];
    }else {
        NSString *error = [deserialisedSession objectForKey:@"error"];
        if (error) {
            NSDictionary *userInfo = [[NSDictionary alloc]initWithObjectsAndKeys:error, @"printableError", nil];
            NSError *serverError = [[NSError alloc] initWithDomain:@"com.custom.domain" code:500 userInfo:userInfo];
            [delegate fetchingDataFailedWithError:serverError];
        } else {
            NSString *email = [[deserialisedSession objectForKey:@"token"] objectForKey:@"email"];
            NSString *userId = [[deserialisedSession objectForKey:@"token"]objectForKey:@"userId"];
            NSString *tokenId = [[deserialisedSession objectForKey:@"token"]objectForKey:@"id"];
            NSString *msg = [deserialisedSession objectForKey:@"msg"];
            Session *session = [[Session alloc] initWithEmail:email userId:userId tokenId:tokenId];
            [delegate didReceiveSession:session message:msg];
        }
    }
}

- (void)resetCodeWasSent:(NSData *)data {
    NSError *error = nil;
    NSDictionary *deserialisedMsg = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        NSDictionary *newUserInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"Unable to parse server response. Please do something!", @"printableError", nil];
        NSError *newError = [[NSError alloc] initWithDomain:@"com.custom.domain" code:500 userInfo:newUserInfo];
        [delegate fetchingDataFailedWithError:newError];
    } else {
        NSString *error = [deserialisedMsg objectForKey:@"error"];
        if (error) {
            NSDictionary *userInfo = [[NSDictionary alloc]initWithObjectsAndKeys:error, @"printableError", nil];
            NSError *serverError = [[NSError alloc] initWithDomain:@"com.custom.domain" code:500 userInfo:userInfo];
            [delegate fetchingDataFailedWithError:serverError];
        }else {
            NSString *msg = [deserialisedMsg objectForKey:@"msg"];
            [delegate resetCodeSuccessMessageWasReceived:msg];
        }
    }
}


@end




















