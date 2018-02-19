//
//  CALayer+XibConfiguration.m
//  Grab
//
//  Created by Tim Carr on 9/3/15.
//  Copyright (c) 2015 Tim Carr. All rights reserved.
//

#import "CALayer+XibConfiguration.h"

@implementation CALayer(XibConfiguration)

- (void)setBorderUIColor:(UIColor*)color {
    self.borderColor = color.CGColor;
}

- (UIColor*)borderUIColor {
    return [UIColor colorWithCGColor:self.borderColor];
}

@end