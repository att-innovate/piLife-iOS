//
//  NSMutableURLRequest+BasicAuth.h
//  piLife
//
//  Created by Virginia Ng on 10/6/14.
//  Copyright (c) 2014 Virginia Ng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (BasicAuth)

+ (void)basicAuthForRequest:(NSMutableURLRequest *)request withUsername:(NSString *)username andPassword:(NSString *)password;

@end
