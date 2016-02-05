//
//  OpenCVWrapper.h
//  Amazing Mask
//
//  Created by 刘洋 on 16/2/1.
//  Copyright © 2016年 Louie. All rights reserved.
//




#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>


@interface OpenCVWrapper : NSObject

-(NSMutableArray*)FaceDetectionWithOpenCVCascade: (UIImage*)Image;

-(UIImage*)changeRoiOfImage: (UIImage*)Image Roi:(CGRect)Roi Mask:(UIImage*)Mask;

@end
