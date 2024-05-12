#import "BetterPlayerEzDrmAssetsLoaderDelegate.h"

@implementation BetterPlayerEzDrmAssetsLoaderDelegate

NSString *_assetId;

NSString *DEFAULT_LICENSE_SERVER_URL = @"https://fps.ezdrm.com/api/licenses/";

- (instancetype)init:(NSURL *)certificateURL withLicenseURL:(NSURL *)key_request_url {
    self = [super init];
    _certificateURL = certificateURL;
    _key_request_url = key_request_url;
    return self;
}

- (NSData *)getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest:(NSData *)requestBytes
                                                               and:(NSString *)assetId
                                                               and:(NSString *)customParams
                                                               and:(NSError *)errorOut {
    NSData *decodedData;
    NSURLResponse *response;

    NSURL *finalLicenseURL;
    if (_key_request_url != [NSNull null]) {
        finalLicenseURL = _key_request_url;
    } else {
        finalLicenseURL = [[NSURL alloc] initWithString:DEFAULT_LICENSE_SERVER_URL];
    }
    
    // Construct the key request URL using the FairPlay Streaming Guide
    NSString *keyRequestURLString = [NSString stringWithFormat:@"%@%@%@", finalLicenseURL, assetId, customParams];
    NSURL *ksmURL = [NSURL URLWithString:keyRequestURLString];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:ksmURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:requestBytes];

    @try {
        decodedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    }
    @catch (NSException *excp) {
        NSLog(@"SDK Error, SDK responded with Error: (error)");
    }
    return decodedData;
}

- (NSData *)getAppCertificate:(NSString *)String {
    NSData *certificate = nil;
    certificate = [NSData dataWithContentsOfURL:_certificateURL];
    return certificate;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURL *assetURI = loadingRequest.request.URL;
    NSString *str = assetURI.absoluteString;
    NSString *mySubstring = [str substringFromIndex:str.length - 36];
    _assetId = mySubstring;
    NSString *scheme = assetURI.scheme;
    NSData *requestBytes;
    NSData *certificate;

    if (!([scheme isEqualToString:@"skd"])) {
        return NO;
    }

    @try {
        certificate = [self getAppCertificate:_assetId];
    } @catch (NSException *excp) {
        [loadingRequest finishLoadingWithError:[[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorClientCertificateRejected userInfo:nil]];
    }
    @try {
        requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate
                                                       contentIdentifier:[str dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:nil
                                                                   error:nil];
    } @catch (NSException *excp) {
        [loadingRequest finishLoadingWithError:nil];
        return YES;
    }


    // Step 5: Generate a JSON block with the following data
    NSDictionary *jsonBlock = @{
        @"application_id": @"",
        @"key_id": @"",
        @"x-bolt-offline-license": @"true",
        @"x-bc-crt-config": @"eyJwcm9maWxlIjp7InB1cmNoYXNlIjp7fX19",
        @"publisher_id": @"",
        @"server_playback_context": [requestBytes base64EncodedStringWithOptions:0]
    };

    // Step 6.1: Make a request to the license server
    NSData *jsonBlockData = [NSJSONSerialization dataWithJSONObject:jsonBlock options:0 error:nil];

    NSString *passthruParams = [NSString stringWithFormat:@"?customdata=%@", _assetId];
    NSData *responseData;
    NSError *error;

    responseData = [self getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest:jsonBlockData and:_assetId and:passthruParams and:error];

    if (responseData != nil && responseData != NULL && ![responseData isKindOfClass:[NSNull class]]) {
        AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
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
