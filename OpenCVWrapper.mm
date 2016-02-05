//
//  OpenCVWrapper.m
//  Amazing Mask
//
//  Created by 刘洋 on 16/2/1.
//  Copyright © 2016年 Louie. All rights reserved.
//

#import "OpenCVWrapper.h"

#include <string>
#include <vector>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/ios.h>

@implementation OpenCVWrapper

-(NSMutableArray*)FaceDetectionWithOpenCVCascade: (UIImage*)Image
{
    cv::Mat matImage;
    UIImageToMat(Image, matImage);

    std::string face_cascade_name = *new std::string([NSHomeDirectory() UTF8String]);
    face_cascade_name += "/Documents/cascade.xml";
    
    cv::CascadeClassifier face_cascade;
    
    if (!face_cascade.load(face_cascade_name))
    {
        std::cerr << "Can not load the cascade" << std::endl;
    }
    
    std::vector<cv::Rect> faces;
    cv::Mat gray;
    cv::cvtColor(matImage, gray, CV_RGB2GRAY);
    
    cv::equalizeHist(gray, gray);
    double min = MIN(gray.rows, gray.cols) / 7;
    min = min > 100 ? 100: min;
    face_cascade.detectMultiScale(gray, faces, 1.5, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(min, min));
    
    NSMutableArray* roiRects = [NSMutableArray arrayWithCapacity:faces.size()];
    for (auto &roi: faces)
    {
        NSValue* tmp = [NSValue valueWithCGRect:CGRectMake(roi.x, roi.y, roi.width, roi.height)];
        [roiRects addObject:tmp];
    }
    
    
    return roiRects;
}

-(UIImage*)changeRoiOfImage: (UIImage*)Image Roi:(CGRect)Roi Mask:(UIImage*)Mask
{
    cv::Mat MatImage;
    UIImageToMat(Image, MatImage);
    cv::Mat MatMask;
    UIImageToMat(Mask, MatMask);
    
    cv::resize(MatMask, MatMask, cv::Size(Roi.size.width, Roi.size.height));

    cv::Rect targetRoi;
    cv::Rect sourceRoi;
    
    if (Roi.origin.x < 0)
    {
        targetRoi.x = 0;
        sourceRoi.x = -Roi.origin.x;
    }
    else
    {
        targetRoi.x = Roi.origin.x;
        sourceRoi.x = 0;
    }
    
    if (Roi.origin.y < 0)
    {
        targetRoi.y = 0;
        sourceRoi.y = -Roi.origin.y;
    }
    else
    {
        targetRoi.y = Roi.origin.y;
        sourceRoi.y = 0;
    }
    
    if (Roi.origin.x + Roi.size.width >= MatImage.cols)
    {
        targetRoi.width = MatImage.cols - 1 - Roi.origin.x;
        sourceRoi.width = targetRoi.width;
    }
    else
    {
        targetRoi.width = Roi.size.width - sourceRoi.x;
        sourceRoi.width = targetRoi.width;
    }
    
    if (Roi.origin.y + Roi.size.height >= MatImage.rows)
    {
        targetRoi.height = MatImage.rows - 1 - Roi.origin.x;
        sourceRoi.height = targetRoi.height;
    }
    else
    {
        targetRoi.height = Roi.size.height - sourceRoi.y;
        sourceRoi.height = targetRoi.height;
    }
    
    MatMask(sourceRoi).copyTo(MatImage(targetRoi), MatMask(sourceRoi));
    
    return MatToUIImage(MatImage);
}

@end
