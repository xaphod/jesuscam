#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AVCaptureDevice+FastttCamera.h"
#import "FastttCamera.h"
#import "FastttCameraInterface.h"
#import "FastttCameraTypes.h"
#import "FastttCapturedImage+Process.h"
#import "FastttCapturedImage.h"
#import "FastttFocus.h"
#import "FastttZoom.h"
#import "IFTTTDeviceOrientation.h"
#import "UIImage+FastttCamera.h"
#import "UIViewController+FastttCamera.h"

FOUNDATION_EXPORT double FastttCameraVersionNumber;
FOUNDATION_EXPORT const unsigned char FastttCameraVersionString[];

