//
//  Utils.swift
//  Jesuscam
//
//  Created by Tim Carr on 2/19/18.
//  Copyright © 2018 ICF. All rights reserved.
//

import UIKit

extension CGSize {
    func atScreenScale() -> CGSize {
        return CGSize.init(width: self.width * UIScreen.main.scale, height: self.height * UIScreen.main.scale)
    }
    
    func atAspectRatio(_ aspectRatio: CGSize) -> CGSize {
        guard self.width > 0, self.height > 0, aspectRatio.width > 0, aspectRatio.height > 0 else {
            assert(false, "ERROR")
            return self
        }
        
        var retval = CGSize.zero
        if (aspectRatio.width / self.width) > (aspectRatio.height / self.height) {
            retval.width = self.width
            retval.height = aspectRatio.height * (self.width / aspectRatio.width)
        } else {
            retval.height = self.height
            retval.width = aspectRatio.width * (self.height / aspectRatio.height)
        }
        return retval
    }
    
    func aspectFillInSize(_ into: CGSize, canEnlarge: Bool = false) -> CGSize {
        guard self.width > 0, self.height > 0, into.width > 0, into.height > 0 else {
            assert(false, "ERROR")
            return self
        }
        if self.width < into.width && self.height < into.height && !canEnlarge {
            return self
        }
        
        var minimumSize = into
        let mW = minimumSize.width / self.width
        let mH = minimumSize.height / self.height
        
        if( mH > mW ) {
            minimumSize.width = minimumSize.height / self.height * self.width;
        }
        else if( mW > mH ) {
            minimumSize.height = minimumSize.width / self.width * self.height;
        }
        
        if !canEnlarge && (minimumSize.width > self.width || minimumSize.height > self.height) {
            return self
        }
        return minimumSize
    }
}
