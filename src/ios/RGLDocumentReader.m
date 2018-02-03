//
//  RGLDocumentReader.m
//  CordovaDocumentReader
//
//  Created by Dmitry Smolyakov on 9/16/17.
//  Copyright © 2017 Dmitry Smolyakov. All rights reserved.
//

#import "RGLDocumentReader.h"
@import DocumentReader;

@implementation RGLDocumentReader

- (void) scanDocument:(CDVInvokedUrlCommand*)command {

    [self.commandDelegate runInBackground:^{

        NSData *licenseData = [[command arguments] objectAtIndex:0];

        DocReader *docReader = [[DocReader alloc] initWithProcessParams:nil];
        docReader.processParams.mrz = YES;
        docReader.processParams.barcode = YES;
        docReader.processParams.ocr = NO;
        docReader.processParams.locate = NO;
        docReader.processParams.imageQA = NO;
        docReader.videoCaptureMotionControl = NO;

        NSError *error = nil;
        BOOL docReaderIsReady = [docReader initializeReaderWithLicense:licenseData error:&error];

        if (docReaderIsReady) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [docReader showScanner:self.viewController completion:^(DocReaderAction action, DocumentReaderResults *result, NSString *error) {
                    switch (action) {
                        case DocReaderActionComplete: {
                            if (result != nil) {
                                NSMutableArray *results = [NSMutableArray array];
                                for (DocumentReaderJsonResultGroup *resultObject in result.jsonResult.results) {
                                    [results addObject:resultObject.jsonResult];
                                }
                                CDVPluginResult* pluginResult = [CDVPluginResult
                                                                 resultWithStatus:CDVCommandStatus_OK
                                                                 messageAsArray:[results copy]];
                                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                            }
                        }
                        break;
                        case DocReaderActionCancel: {
                            CDVPluginResult* pluginResult = [CDVPluginResult
                                                             resultWithStatus:CDVCommandStatus_OK
                                                             messageAsString:@"Cancelled by user"];
                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        }
                        break;
                        case DocReaderActionError: {
                            CDVPluginResult* pluginResult = [CDVPluginResult
                                                             resultWithStatus:CDVCommandStatus_ERROR
                                                             messageAsString:error];
                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        }
                        break;
                        default:
                        break;
                    }
                }];
            });
        }
    }];
}    
@end
