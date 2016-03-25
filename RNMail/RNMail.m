#import <MessageUI/MessageUI.h>

#import "RNMail.h"
#import "RCTConvert.h"
#import "RCTLog.h"

@implementation RNMail
{
    NSMutableDictionary *_callbacks;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _callbacks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(mail:(NSDictionary *)options
                  callback: (RCTResponseSenderBlock)callback)
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        _callbacks[RCTKeyForInstance(mail)] = callback;
        
        if (options[@"subject"]){
            NSString *subject = [RCTConvert NSString:options[@"subject"]];
            [mail setSubject:subject];
        }
        
        if (options[@"body"]){
            NSString *body = [RCTConvert NSString:options[@"body"]];
            [mail setMessageBody:body isHTML:NO];
        }
        
        if (options[@"recipients"]){
            NSArray *recipients = [RCTConvert NSArray:options[@"recipients"]];
            [mail setToRecipients:recipients];
        }
        
        // do not force user to enter a mime type
        //if (options[@"attachment"] && options[@"attachment"][@"path"] && options[@"attachment"][@"type"]){
        if (options[@"attachment"] && options[@"attachment"][@"path"]){
            NSString *attachmentPath = [RCTConvert NSString:options[@"attachment"][@"path"]];
            NSString *attachmentType = [RCTConvert NSString:options[@"attachment"][@"type"]];
            NSString *attachmentName = [RCTConvert NSString:options[@"attachment"][@"name"]];
            
            // Set default filename if not specificed
            if (!attachmentName) {
                attachmentName = [[attachmentPath lastPathComponent] stringByDeletingPathExtension];
            }
            
            // Get the resource path and read the file using NSData
            NSData *fileData = [NSData dataWithContentsOfFile:attachmentPath];
            
            // Determine the MIME type
            NSString *mimeType;
            
            if ([attachmentType isEqualToString:@"jpg"]) {
                mimeType = @"image/jpeg";
            } else if ([attachmentType isEqualToString:@"png"]) {
                mimeType = @"image/png";
            } else if ([attachmentType isEqualToString:@"doc"]) {
                mimeType = @"application/msword";
            } else if ([attachmentType isEqualToString:@"ppt"]) {
                mimeType = @"application/vnd.ms-powerpoint";
            } else if ([attachmentType isEqualToString:@"html"]) {
                mimeType = @"text/html";
            } else if ([attachmentType isEqualToString:@"pdf"]) {
                mimeType = @"application/pdf";
            } else if ([attachmentType isEqualToString:@"txt"]) {
                mimeType = @"text/plain";
            }
            
            mimeType = lookupMimeByFileExtension(attachmentPath);
            
            // Add attachment
            [mail addAttachmentData:fileData mimeType:mimeType fileName:attachmentName];
        }
        
        UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [root presentViewController:mail animated:YES completion:nil];
    } else {
        callback(@[@"not_available"]);
    }
}


#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *key = RCTKeyForInstance(controller);
    RCTResponseSenderBlock callback = _callbacks[key];
    if (callback) {
        switch (result) {
            case MFMailComposeResultSent:
                callback(@[[NSNull null] , @"sent"]);
                break;
            case MFMailComposeResultSaved:
                callback(@[[NSNull null] , @"saved"]);
                break;
            case MFMailComposeResultCancelled:
                callback(@[[NSNull null] , @"cancelled"]);
                break;
            case MFMailComposeResultFailed:
                callback(@[@"failed"]);
                break;
            default:
                callback(@[@"error"]);
                break;
        }
        [_callbacks removeObjectForKey:key];
    } else {
        RCTLogWarn(@"No callback registered for mail: %@", controller.title);
    }
    UIViewController *ctrl = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [ctrl dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Private

static NSString *RCTKeyForInstance(id instance)
{
    return [NSString stringWithFormat:@"%p", instance];
}

// Consider a data lookup table that has analogy in Java and Objective C.
// Is there a common file or data format that could be accessed by both Java and Objective C.
// Or a script to update or generate cross platform data file?
//
// tableLookupMimeByFileExtension {
//      { 'ppt', 'application/vnd.ms-powerpoint' },
//      { 'txt', 'text/plain' },
// }
//
static NSString *lookupMimeByFileExtension(NSString* fileName)
{
    NSString *mimeType = @"application/octet-stream";
    NSString* extension = [fileName pathExtension];
    if ([extension isEqualToString:@"txt"]) {
        mimeType = @"text/plain";
    } else if ([extension isEqualToString:@"jpg"]) {
        mimeType = @"image/jpeg";
    } else if ([extension isEqualToString:@"png"]) {
        mimeType = @"image/png";
    } else if ([extension isEqualToString:@"csv"]) {
        mimeType = @"text/csv";
    } else if ([extension isEqualToString:@"doc"]) {
        mimeType = @"application/msword";
    } else if ([extension isEqualToString:@"gpx"]) {
        mimeType = @"application/gpx+xml";
    } else if ([extension isEqualToString:@"ppt"]) {
        mimeType = @"application/vnd.ms-powerpoint";
    } else if ([extension isEqualToString:@"html"]) {
        mimeType = @"text/html";
    } else if ([extension isEqualToString:@"kml"]) {
        mimeType = @"application/vnd.google-earth.kml+xml";
    } else if ([extension isEqualToString:@"pdf"]) {
        mimeType = @"application/pdf";
    } else if ([extension isEqualToString:@"tsr"]) {
        // TSR OS X sends as this:
        // Content-Type: application/octet-stream; name="JOB-0001.tsr"
        mimeType = @"application/vnd.ditchwitch.tsr+xml";
    } else if ([extension isEqualToString:@"TSL"]) {
        // MIME types are case insensitive. They are lowercase by convention only.
        // RFC 2045: http://tools.ietf.org/html/rfc2045
        mimeType = @"application/vnd.ditchwitch.tsl+xml";
    } else {
        RCTLogWarn(@"Unsupported email attachment file extension %@", extension);
    }
    
    return mimeType;
}


@end
