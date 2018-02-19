//
//  UIImage+Utils.h
//  Photobooth
//
//  Created by Tim Carr on 6/17/15.
//  Copyright (c) 2015 Tim Carr Photo. All rights reserved.
//

@import UIKit;

@interface UIImage (Utils)

- (UIImage* _Nonnull)tiltAndZoomImage;
- (UIImage* _Nonnull)imageRotatedByRadiansWithAngle:(CGFloat)angle;
- (UIImage* _Nonnull)cropImageToFillSize:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale;
- (UIImage* _Nonnull)cropImageToFillSize:(CGSize)size opaque:(BOOL)opaque centerImage:(BOOL)centerImage scale:(CGFloat)scale;

- (CGSize)aspectFitSizeInSize:(CGSize)size allowEnlarge:(BOOL)allowEnlarge;
- (UIImage* _Nonnull)resizeImageWithCoreGraphics:(CGSize)size; // use this as default, it will call lanczos if needed for CIImage-backed UIImage
- (UIImage* _Nonnull)resizeImageWithLanczos:(CGSize)size; // warning, not for use when resizing images to very small images
- (UIImage* _Nonnull)resizeImageWithUIKitToNoLargerThanSize:(CGSize)size opaque:(BOOL)opaque; // warning, not for use for large images

- (UIImage* _Nonnull)matteImageInSize:(CGSize)size opaque:(BOOL)opaque backgroundColor:(UIColor*)backgroundColor; // always returns an image of size that matches CGSize
- (UIImage* _Nonnull)fixRotationWithMirror:(BOOL)mirror;
- (UIImage* _Nonnull)fixRotationWithMirror:(BOOL)mirror imageOrientation:(UIImageOrientation)orientation;
- (NSData* _Nullable)jpgDataAtPrintQuality;

+ (UIImage* _Nonnull)color:(UIColor*)color size:(CGSize)size;
+ (UIImage* _Nonnull)color:(UIColor*)color;

@end
