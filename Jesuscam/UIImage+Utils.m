//
//  UIImage+Utils.m
//  Photobooth
//
//  Created by Tim Carr on 6/17/15.
//  Copyright (c) 2015 Tim Carr Photo. All rights reserved.
//

#import "UIImage+Utils.h"

@implementation UIImage (Utils)

// private - adds a random amount of tilt & zoom to make the image more interesting
- (UIImage* _Nonnull)tiltAndZoomImage {
    
    NSInteger tiltAngle = [self getRandomNumberBetween:0 maxNumber:20];
    tiltAngle = tiltAngle - 10;
    NSInteger extraZoom = [self getRandomNumberBetween:0 maxNumber:20];
    extraZoom = 1 + (extraZoom/100);
    NSLog(@"Tilting with angle %ld", (long)tiltAngle);
    
    UIImage* processedImage = [self imageRotatedByRadiansWithAngle:tiltAngle];
    
    return processedImage;
}

// this rotates within the view-box of the original
- (UIImage* _Nonnull)imageRotatedByRadiansWithAngle:(CGFloat)angle
{
    @autoreleasepool {
        
        NSLog(@"imageRotatedByRadiansWithAngle, start");
        CGFloat radians = angle * (M_PI / 180);
        
        // calculate the size of the rotated view's containing box for our drawing space
        UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
        CGAffineTransform t = CGAffineTransformMakeRotation(radians);
        rotatedViewBox.transform = t;
        CGSize rotatedSize = rotatedViewBox.frame.size;
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        CGContextRef bitmap = UIGraphicsGetCurrentContext();
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
        
        //Rotate the image context
        CGContextRotateCTM(bitmap, radians);
        
        // Now, draw the rotated/scaled image into the context
        //    CGContextScaleCTM(bitmap, 1.0, -1.0);
        CGFloat scaleFactor = angle;
        if( scaleFactor < 0)
            scaleFactor *= -1;
        CGContextScaleCTM(bitmap, 1 + (scaleFactor/18), (1 + (scaleFactor/18)) * -1);
        
        CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSLog(@"imageRotatedByRadiansWithAngle, end");
        if (!newImage)
            return self;
        return newImage;
    }
}

// DESIRED BEHAVIOR: BIGGEST SIZE THAT FITS SUCH THAT ASPECT-RATIO STAYS THE SAME. Does not upscale.
- (CGSize)aspectFitSizeInSize:(CGSize)size allowEnlarge:(BOOL)allowEnlarge {
    if( !allowEnlarge && self.size.width <= size.width && self.size.height <= size.height )
        return self.size;
    
    CGFloat width, height;
    if( (self.size.width / size.width) > (self.size.height / size.height) ) {
        
        // resize width
        width = size.width;
        height = self.size.height * (size.width/self.size.width);
    } else {
        
        height = size.height;
        width = self.size.width * (size.height/self.size.height);
    }
    return CGSizeMake(width, height);
}

- (UIImage* _Nonnull)resizeImageWithCoreGraphics:(CGSize)size {
    @autoreleasepool {
        if (CGSizeEqualToSize(self.size, size))
            return self;
        
        if (!self.CGImage) {
            NSAssert(false, @"ERROR: expect images to have CGimage!");
            if (self.CIImage) {
                // using CoreImage-lanczos instead
                return [self resizeImageWithLanczos:size];
            } else {
                return self;
            }
        }
        
        CGSize aspectFitSize = [self aspectFitSizeInSize:size allowEnlarge:NO];
        if (CGSizeEqualToSize(self.size, aspectFitSize))
            return self;
        CGFloat width = aspectFitSize.width;
        CGFloat height = aspectFitSize.height;
        
#ifndef RELEASE
        NSDate *perfTimerStart = [NSDate date];
#endif
        
        size_t bitsPerComponent = CGImageGetBitsPerComponent(self.CGImage);
        size_t bytesPerRow = CGImageGetBytesPerRow(self.CGImage);
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.CGImage);
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(self.CGImage);
        
        CGContextRef context = CGBitmapContextCreate(nil, (unsigned long)round(width), (unsigned long)round(height), bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), self.CGImage);
        CGImageRef scaledImageRef = CGBitmapContextCreateImage(context);
        UIImage *scaledImage = [UIImage imageWithCGImage:scaledImageRef];
        CGImageRelease(scaledImageRef);
        CGContextRelease(context);
        
#ifndef RELEASE
        NSTimeInterval perf = ABS([perfTimerStart timeIntervalSinceNow]);
        NSLog(@"UIImage+Utils: CoreGraphics resize from w:%d h:%d to w:%d h:%d took %1.4lf sec", (int)round(self.size.width), (int)round(self.size.height), (int)round(scaledImage.size.width), (int)round(scaledImage.size.height), perf);
#endif
        
        if (!scaledImage)
            return self;
        return scaledImage;
    }
}

- (UIImage* _Nonnull)resizeImageWithLanczos:(CGSize)size {
    if (CGSizeEqualToSize(self.size, size))
        return self;

    @autoreleasepool {

        CGSize aspectFitSize = [self aspectFitSizeInSize:size allowEnlarge:NO];
        if (CGSizeEqualToSize(self.size, aspectFitSize))
            return self;
        CGFloat width = aspectFitSize.width;
        NSNumber *scale = [NSNumber numberWithDouble:width / self.size.width];
      
        static CIContext *context = nil;
        if (!context) {
            context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@NO}];
        }
        
#ifndef RELEASE
        NSLog(@"UIImage+Utils: CIContext INPUTMAX w:%d h:%d, OUTPUTMAX w:%d h:%d", (int)context.inputImageMaximumSize.width, (int)context.inputImageMaximumSize.height, (int)context.outputImageMaximumSize.width, (int)context.outputImageMaximumSize.height);

        NSDate *perfTimerStart = [NSDate date];
#endif
        if (self.size.width > context.inputImageMaximumSize.width || self.size.height > context.inputImageMaximumSize.height) {
            NSAssert(false, @"too big!");
            NSLog(@"UIImage+Utils, Lanczos resize: ERROR, input image too big -- w:%d h:%d, max input w:%d h:%d", (int)self.size.width, (int)self.size.height, (int)context.inputImageMaximumSize.width, (int)context.inputImageMaximumSize.height);
        }
        
        
        CIImage *ciimage = nil;
        if (self.CIImage) {
            ciimage = self.CIImage;
        } else {
            if (self.CGImage)
                ciimage = [[CIImage alloc] initWithCGImage:self.CGImage];
            else
                return self;
        }
        
        CIFilter *filter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [filter setValue:ciimage forKey:@"inputImage"];
        [filter setValue:scale forKey:@"inputScale"];
        [filter setValue:@1.0 forKey:@"inputAspectRatio"];
        CIImage *outputImage = [filter valueForKey:@"outputImage"];

        CGImageRef cgImage = [context createCGImage:outputImage fromRect:outputImage.extent]; // can still fail to malloc here even if size is less than max!
        UIImage *scaledImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        
#ifndef RELEASE
        NSTimeInterval perf = ABS([perfTimerStart timeIntervalSinceNow]);
        NSLog(@"UIImage+Utils: LANCZOSScaleTransform from w:%d h:%d to w:%d h:%d took %1.4lf sec", (int)round(self.size.width), (int)round(self.size.height), (int)round(scaledImage.size.width), (int)round(scaledImage.size.height), perf);
#endif
        if (!scaledImage)
            return self;
        return scaledImage;
    }
}

- (UIImage* _Nonnull)resizeImageWithUIKitToNoLargerThanSize:(CGSize)size opaque:(BOOL)opaque {
    if (CGSizeEqualToSize(self.size, size))
        return self;
    CGSize aspectFitSize = [self aspectFitSizeInSize:size allowEnlarge:NO];
    if (CGSizeEqualToSize(self.size, aspectFitSize))
        return self;
    CGFloat width = aspectFitSize.width;
    CGFloat height = aspectFitSize.height;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width,height), opaque, self.scale);
    [self drawInRect:CGRectMake(0,0,width,height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (!newImage)
        return self;
    return newImage;
}

// DESIRED BEHAVIOR: ALWAYS OUTPUT IMAGE WITH A SIZE EQUAL TO INPUTTED SIZE.
// IF IMAGE IS SMALLER THAN INPUTTED SIZE, ENLARGE THE IMAGE SO THE SIZE IS TOTALLY FILLED
// IF IMAGE IS LARGER THAN INPUTTED SIZE, RESIZE DOWN AND KEEP ASPECT-RATIO BUT MAKE SURE SIZE IS TOTALLY FILLED
- (UIImage* _Nonnull)cropImageToFillSize:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale {
    return [self cropImageToFillSize:size opaque:opaque centerImage:true scale:scale];
}

- (UIImage* _Nonnull)cropImageToFillSize:(CGSize)size opaque:(BOOL)opaque centerImage:(BOOL)centerImage scale:(CGFloat)scale {
    @autoreleasepool {
        if (CGSizeEqualToSize(self.size, size))
            return self;
        
        CGFloat rescale = MAX(size.width/self.size.width, size.height/self.size.height);
        CGFloat width = self.size.width * rescale;
        CGFloat height = self.size.height * rescale;
        
        CGFloat x=0, y=0;
        if (centerImage) {
            // we assume at this point one side of self is equal to destination size, other is bigger.
            // because of floats, look for the bigger difference
            if( ABS(width-size.width) > ABS(height-size.height) ) {
                // width has bigger difference, center the x
                x = (size.width - width)/2.0f;
            } else {
                y = (size.height - height)/2.0f;
            }
        }
        
        CGRect imageRect = CGRectMake(x,
                                      y,
                                      width,
                                      height);
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
        [self drawInRect:imageRect];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (!newImage)
            return self;
        return newImage;
    }
}


// DESIRED BEHAVIOR: ALWAYS OUTPUT IMAGE WITH A SIZE EQUAL TO INPUTTED SIZE.
// IF IMAGE IS SMALLER THAN INPUTTED SIZE, PUT WHITESPACE AROUND IT
// IF IMAGE IS LARGER THAN INPUTTED SIZE, RESIZE DOWN AND KEEP ASPECT-RATIO
// Cases
// 1. image is smaller in width and height than inputted size. Expected behavior: matte (no upsize)
// 2. image has one side that is smaller than inputted size, other is equal or larger. Expected behavior: image is sized down until larger side matches inputted size
// 3. image has both sides equal to inputted size. Expected behavior: no-op
// 4. image has both sides larger than inputted size. Expected behavior: larger side of image is sized down until it matches inputted size
//
// 3 is special case
// 2 and 4 are the same remedy
- (UIImage* _Nonnull)matteImageInSize:(CGSize)size opaque:(BOOL)opaque backgroundColor:(UIColor*)backgroundColor {
    @autoreleasepool {

        if( CGSizeEqualToSize(self.size, CGSizeZero) )
            return self;
        if( CGSizeEqualToSize(size, CGSizeZero) )
            return self;
        
        // case 3: same size is no-op
        if( CGSizeEqualToSize(self.size, size) )
           return self;
        
        CGRect imageRect;
        
        if( self.size.width < size.width && self.size.height < size.height ) {

            // case 1: a smaller image needs a matte, in center
            imageRect = CGRectMake( (size.width-self.size.width)/2.0f, (size.height-self.size.height)/2.0f, self.size.width, self.size.height);
        } else {
            
            // case 2 or 4: at least one size is too big and needs to shrink down, keeping aspect ratio. Choose largest size to shrink down.
            CGFloat scale = MIN(size.width/self.size.width, size.height/self.size.height);
            NSAssert( scale < 1, @"ERROR: shouldnt be possible to have scale >= 1" );
            CGFloat width = self.size.width * scale;
            CGFloat height = self.size.height * scale;
            CGFloat x = (size.width-width)/2.0f;
            CGFloat y = (size.height-height)/2.0f;
            
            // center image
            if( size.width/self.size.width < size.height/self.size.height ) {
                // height needs to be centered
                imageRect = CGRectMake(0, y, width, height);
            } else {
                // width needs to be centered
                imageRect = CGRectMake(x, 0, width, height);
            }
            
        }
        
        UIGraphicsBeginImageContextWithOptions(size, opaque, self.scale);
        [backgroundColor setFill]; // otherwise it's ugly black fill
        UIRectFill(CGRectMake(0, 0, size.width, size.height));
        [self drawInRect:imageRect];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (!newImage)
            return self;
        return newImage;
    }
}

- (UIImage* _Nonnull)fixRotationWithMirror:(BOOL)mirror {
    return [self fixRotationWithMirror:mirror imageOrientation:self.imageOrientation];
}

- (UIImage* _Nonnull)fixRotationWithMirror:(BOOL)mirror imageOrientation:(UIImageOrientation)orientation {
    if (!self.CGImage)
        return self;
    
    @autoreleasepool {
        if (orientation == UIImageOrientationUp && !mirror) return self;
        NSAssert(!NSThread.currentThread.isMainThread, @"ERROR"); // is in path of GVC scrollview
        CGAffineTransform transform = CGAffineTransformIdentity;
        
        switch (orientation) {
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
                transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
                transform = CGAffineTransformRotate(transform, M_PI);
                break;
                
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
                transform = CGAffineTransformTranslate(transform, self.size.width, 0);
                transform = CGAffineTransformRotate(transform, M_PI_2);
                break;
                
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                transform = CGAffineTransformTranslate(transform, 0, self.size.height);
                transform = CGAffineTransformRotate(transform, -M_PI_2);
                break;
            case UIImageOrientationUp:
            case UIImageOrientationUpMirrored:
                break;
        }
        
        // MIRRORING
        switch (orientation) {
            // already mirrored: unmirror them only if !mirror
            case UIImageOrientationUpMirrored:
            case UIImageOrientationDownMirrored:
                if (!mirror) {
                    transform = CGAffineTransformTranslate(transform, self.size.width, 0);
                    transform = CGAffineTransformScale(transform, -1, 1);
                }
                break;
                
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRightMirrored:
                if (!mirror) {
                    transform = CGAffineTransformTranslate(transform, self.size.height, 0);
                    transform = CGAffineTransformScale(transform, -1, 1);
                }
                break;
                
            // not mirrored: mirror them only if mirror==true
            case UIImageOrientationUp:
            case UIImageOrientationDown:
                if (mirror) {
                    transform = CGAffineTransformTranslate(transform, self.size.width, 0);
                    transform = CGAffineTransformScale(transform, -1, 1);
                }
                break;
                
                
            case UIImageOrientationLeft:
            case UIImageOrientationRight:
                if (mirror) {
                    transform = CGAffineTransformTranslate(transform, 0, self.size.width);
                    transform = CGAffineTransformScale(transform, 1, -1);
                }
                break;
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                                 8, self.size.width * 4.0, colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGContextConcatCTM(ctx, transform);
        switch (orientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                // Grr...
                CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
                break;
                
            default:
                CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
                break;
        }
        
        // And now we just create a new UIImage from the drawing context
        CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
        UIImage *img = [UIImage imageWithCGImage:cgimg];
        CGContextRelease(ctx);
        CGColorSpaceRelease(colorspace);
        CGImageRelease(cgimg);
        //NSLog(@"fixRotation: END");
        if (!img)
            return self;
        return img;
    }
}

- (NSData* _Nullable)jpgDataAtPrintQuality {
    @autoreleasepool {
        NSData* printData = UIImageJPEGRepresentation(self, 0.8);
        if( printData == nil || printData.length <= 0 ) {
            NSAssert(false, @"ERROR: JPG image data for collage is nil/0" );
            return nil;
        }
        return printData;
    }
}

- (NSInteger)getRandomNumberBetween:(NSInteger)min maxNumber:(NSInteger)max
{
    // we don't care about modulo bias
    return min + arc4random() % (max - min + 1);
}

+ (UIImage* _Nonnull)color:(UIColor*)color {
    return [UIImage color:color size:CGSizeMake(1, 1)];
}

+ (UIImage* _Nonnull)color:(UIColor*)color size:(CGSize)size {
    if (CGSizeEqualToSize(size, CGSizeZero))
        size = CGSizeMake(1, 1);
    UIGraphicsBeginImageContextWithOptions(size, false, 0);
    [color setFill];
    UIRectFill(CGRectMake(0,0,size.width,size.height));
    UIImage *retval = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retval;
}

@end
