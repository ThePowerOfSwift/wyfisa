//
//  ImageFilter.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/23/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import GPUImage


/* 
 * Image Filtering and Transforms
 */
class ImageFilter {
    class func genericFilter() -> GPUImageFilter {
        return GPUImageFilter()
    }
    
    class func guassianBlur(x: CGFloat, y: CGFloat, radius: CGFloat) -> GPUImageGaussianSelectiveBlurFilter {
        
        let guassFilter = GPUImageGaussianSelectiveBlurFilter()
        guassFilter.excludeCircleRadius = radius
        guassFilter.excludeCirclePoint = CGPoint(x: x, y: y)
        return guassFilter
    }
    
    class func darkenFilter(brightness: CGFloat) -> GPUImageBrightnessFilter {
        let filter =  GPUImageBrightnessFilter()
        filter.brightness = brightness
        return filter
    }
    
    class func magnify(size: CGSize, by: CGFloat) -> GPUImageLanczosResamplingFilter {
        let filter = GPUImageLanczosResamplingFilter()
        let newSize = CGSize.init(width: size.width*by, height: size.height*by)
        filter.forceProcessingAtSize(newSize)
        return filter
    }

    class func cropFilter(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> GPUImageCropFilter {
        let cropArea = CGRect(x: x, y: y, width: width, height: height)
        return GPUImageCropFilter(cropRegion: cropArea)
    }
    
    class func thresholdFilter(radius: CGFloat) -> GPUImageAdaptiveThresholdFilter {
        let thresholdFilter = GPUImageAdaptiveThresholdFilter()
        thresholdFilter.blurRadiusInPixels = radius
        return thresholdFilter
    }
    
    class func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    class func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
        } else {
            newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
