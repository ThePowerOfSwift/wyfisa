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
    
    class func guassianBlur(radius: CGFloat) -> GPUImageGaussianSelectiveBlurFilter {
        
        let guassFilter = GPUImageGaussianSelectiveBlurFilter()
        guassFilter.excludeCircleRadius = radius
        guassFilter.excludeCirclePoint = CGPoint(x: 0.5, y: 0.15)
        guassFilter.aspectRatio = 1.5
        return guassFilter
    }
    
    class func magnify(size: CGSize, by: CGFloat) -> GPUImageLanczosResamplingFilter {
        let filter = GPUImageLanczosResamplingFilter()
        let newSize = CGSize.init(width: size.width*by, height: size.height*by)
        filter.forceProcessingAtSize(newSize)
        return filter
    }

    class func cropFilter(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> GPUImageCropFilter {
        //upscale then crop
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
        
        return scaledImage
    }
}