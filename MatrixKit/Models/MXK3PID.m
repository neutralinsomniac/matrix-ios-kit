/*
 Copyright 2015 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXK3PID.h"

@interface MXK3PID ()
{
    MXRestClient *mxRestClient;
    MXHTTPOperation *currentRequest;
}
@property (nonatomic) NSString *clientSecret;
@property (nonatomic) NSUInteger sendAttempt;
@property (nonatomic) NSString *sid;
@end

@implementation MXK3PID

- (instancetype)initWithMedium:(NSString *)medium andAddress:(NSString *)address
{
    self = [super init];
    if (self)
    {
        _medium = [medium copy];
        _address = [address copy];
        self.clientSecret = [MXTools generateSecret];
    }
    return self;
}

- (void)cancelCurrentRequest
{
    _validationState = MXK3PIDAuthStateUnknown;
    
    [currentRequest cancel];
    currentRequest = nil;
    mxRestClient = nil;

    self.sendAttempt = 1;
    self.sid = nil;
    // Removed potential linked userId
    self.userId = nil;
}

- (void)requestValidationTokenWithMatrixRestClient:(MXRestClient*)restClient
                                          nextLink:(NSString*)nextLink
                                           success:(void (^)())success
                                           failure:(void (^)(NSError *error))failure
{
    // Sanity Check
    if (_validationState != MXK3PIDAuthStateTokenRequested && restClient)
    {
        
        // Reset if the current state is different than "Unknown"
        if (_validationState != MXK3PIDAuthStateUnknown)
        {
            [self cancelCurrentRequest];
        }
        
        if ([self.medium isEqualToString:kMX3PIDMediumEmail])
        {
            _validationState = MXK3PIDAuthStateTokenRequested;
            mxRestClient = restClient;
            
            currentRequest = [mxRestClient requestEmailValidation:self.address clientSecret:self.clientSecret sendAttempt:self.sendAttempt nextLink:nextLink success:^(NSString *sid)
            {
                _validationState = MXK3PIDAuthStateTokenReceived;
                currentRequest = nil;
                self.sid = sid;
                
                if (success)
                {
                    success();
                }
            } failure:^(NSError *error)
            {
                // Return in unknown state
                _validationState = MXK3PIDAuthStateUnknown;
                currentRequest = nil;
                // Increment attempt counter
                self.sendAttempt++;
                
                if (failure)
                {
                    failure (error);
                }
            }];
            
            return;
        }
        else if ([self.medium isEqualToString:kMX3PIDMediumMSISDN])
        {
            // FIXME: support msisdn as soon as identity server supports it
            NSLog(@"[MXK3PID] requestValidationToken: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
        }
        else
        {
            NSLog(@"[MXK3PID] requestValidationToken: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
        }
    }
    else
    {
        NSLog(@"[MXK3PID] Failed to request validation token for 3PID: %@ (%@), state: %lu", self.address, self.medium, (unsigned long)_validationState);
    }
}

- (void)add3PIDToUser:(BOOL)bind
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure
{
    if ([self.medium isEqualToString:kMX3PIDMediumEmail])
    {
        __weak typeof(self) weakSelf = self;
        currentRequest = [mxRestClient add3PID:self.sid clientSecret:self.clientSecret bind:bind success:^{

            __strong __typeof(weakSelf)strongSelf = weakSelf;

            // Update linked userId in 3PID
            strongSelf.userId = strongSelf->mxRestClient.credentials.userId;
            currentRequest = nil;

            if (success)
            {
                success();
            }
        } failure:^(NSError *error) {
            currentRequest = nil;

            if (failure)
            {
                failure (error);
            }
        }];

        return;
    }
    else if ([self.medium isEqualToString:kMX3PIDMediumMSISDN])
    {
        // FIXME: support msisdn as soon as identity server supports it
        NSLog(@"[MXK3PID] bindWithUserId: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
    }
    else
    {
        NSLog(@"[MXK3PID] bindWithUserId: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
    }

    // Here the validation process failed
    if (failure)
    {
        failure (nil);
    }
}

@end
