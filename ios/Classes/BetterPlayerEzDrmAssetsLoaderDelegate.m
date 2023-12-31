// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "BetterPlayerEzDrmAssetsLoaderDelegate.h"

@implementation BetterPlayerEzDrmAssetsLoaderDelegate

NSString *_assetId;

NSString * DEFAULT_LICENSE_SERVER_URL = @"https://fps.ezdrm.com/api/licenses/";

- (instancetype)init:(NSURL *)certificateURL withLicenseURL:(NSURL *)licenseURL{
    self = [super init];
    _certificateURL = certificateURL;
    _licenseURL = licenseURL;
    return self;
}

/*------------------------------------------
 **
 ** getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest
 **
 ** Takes the bundled SPC and sends it to the license server defined at licenseUrl or KEY_SERVER_URL (if licenseUrl is null).
 ** It returns CKC.
 ** ---------------------------------------*/
- (NSData *)getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest:(NSData*)requestBytes and:(NSString *)assetId and:(NSString *)customParams and:(NSError *)errorOut {
    NSData * decodedData;
    NSURLResponse * response;
    
    NSURL * finalLicenseURL;
     if (_licenseURL != [NSNull null]){
         finalLicenseURL = _licenseURL;
     } else {
         finalLicenseURL = [[NSURL alloc] initWithString: DEFAULT_LICENSE_SERVER_URL];
     }
    
    
    
    NSString *stringURL = [[NSString stringWithFormat:@"%@%@",finalLicenseURL,assetId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSURL *ksmURL=[NSURL URLWithString:stringURL];
    
    
    
//     NSURL * ksmURL = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@%@",finalLicenseURL,assetId]];
     
     NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:ksmURL];
     [request setHTTPMethod:@"POST"];
     [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
     NSString *accessToken = @"";
     [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];

     
     NSURLComponents *requestBodyComponent = [NSURLComponents new];
      NSString *base64RequestBytes = [requestBytes base64EncodedStringWithOptions:0];
     [requestBodyComponent setQueryItems:@[[NSURLQueryItem queryItemWithName:@"spc" value:base64RequestBytes]]];
     request.HTTPBody = [requestBodyComponent.query dataUsingEncoding:NSUTF8StringEncoding];
     
     NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
     NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
     
     
     
    @try {
        decodedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        
        NSString *responseString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        
        responseString = [responseString stringByReplacingOccurrencesOfString:@"<ckc>" withString:@""];
        responseString = [responseString stringByReplacingOccurrencesOfString:@"</ckc>" withString:@""];
        decodedData = [[NSData alloc] initWithBase64EncodedString:responseString options:0];
        
    }
    @catch (NSException* excp) {
        NSLog(@"SDK Error, SDK responded with Error: (error)");
    }
    return decodedData;
}

/*------------------------------------------
 **
 ** getAppCertificate
 **
 ** returns the apps certificate for authenticating against your server
 ** the example here uses a local certificate
 ** but you may need to edit this function to point to your certificate
 ** ---------------------------------------*/
- (NSData *)getAppCertificate:(NSString *) String {
    NSData * certificate = nil;
    certificate = [NSData dataWithContentsOfURL:_certificateURL];
    return certificate;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURL *assetURI = loadingRequest.request.URL;
    NSString * str = assetURI.host;
    
    NSString * mySubstring = [str substringFromIndex:str.length - 36];
    _assetId = mySubstring;
    NSString * scheme = assetURI.scheme;
    NSData * requestBytes;
    NSData * certificate;
    if (!([scheme isEqualToString: @"skd"])){
        return NO;
    }
    @try {
        certificate = [self getAppCertificate:_assetId];
    }
    @catch (NSException* excp) {
        [loadingRequest finishLoadingWithError:[[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorClientCertificateRejected userInfo:nil]];
    }
    @try {
        requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate contentIdentifier: [str dataUsingEncoding:NSUTF8StringEncoding] options:nil error:nil];
    }
    @catch (NSException* excp) {
        [loadingRequest finishLoadingWithError:nil];
        return YES;
    }
    
    NSString * passthruParams = [NSString stringWithFormat:@"?customdata=%@", _assetId];
    NSData * responseData;
    NSError * error;
    
    
    NSString *query = [assetURI query];

    NSArray *queryComponents = [query componentsSeparatedByString:@"&"];
    NSString *kidValue = nil;

    for (NSString *component in queryComponents) {
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            NSString *key = keyValue[0];
            NSString *value = keyValue[1];
            if ([key isEqualToString:@"kid"]) {
                kidValue = value;
                break;
            }
        }
    }
    
    
    responseData = [self getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest:requestBytes and:kidValue and:passthruParams and:error];
    
    
    
    
    
    if (responseData != nil && responseData != NULL && ![responseData.class isKindOfClass:NSNull.class]){
        AVAssetResourceLoadingDataRequest * dataRequest = loadingRequest.dataRequest;
        [dataRequest respondWithData:responseData];
        [loadingRequest finishLoading];
    } else {
        [loadingRequest finishLoadingWithError:error];
    }
    
    return YES;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest {
    return [self resourceLoader:resourceLoader shouldWaitForLoadingOfRequestedResource:renewalRequest];
}

@end
