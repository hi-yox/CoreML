//
//  ViewController.m
//  CoreMLDemo
//
//  Created by jfdreamyang on 20/09/2017.
//  Copyright © 2017 jfdreamyang. All rights reserved.
//

#import "ViewController.h"
#import <CoreML/CoreML.h>
#import "MobileNet.h"
#import <CoreVideo/CoreVideo.h>
#import <Vision/Vision.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIImage * image=[UIImage imageNamed:@"demo"];
    MobileNet * net=[MobileNet new];
    NSError * err;
    //方法一(适用于简单的单张图片识别)
    VNCoreMLModel * aModel=[VNCoreMLModel modelForMLModel:net.model error:&err];
    VNCoreMLRequest * aRequest=[[VNCoreMLRequest alloc]initWithModel:aModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        
        NSArray<VNClassificationObservation *> * resultArr=request.results;
        
        //一般取前两个即可
        for (VNClassificationObservation * ademo in resultArr) {
            NSLog(@"%@=====%.2f",ademo.identifier,ademo.confidence);
        }
        
    }];
    VNImageRequestHandler * aHandler=[[VNImageRequestHandler alloc]initWithCGImage:image.CGImage options:@{}];
    [aHandler performRequests:@[aRequest] error:nil];
    
//  方法二 此种方法调用CPU讲图片进行转化之后交由CPU处理，不推荐使用
//    CVPixelBufferRef bufferRes=[self pixelBufferFromCGImage:image.CGImage];
//    MobileNetOutput * _netOutPut=[net predictionFromImage:bufferRes error:nil];
//    NSLog(@"%@======%@",_netOutPut.classLabel,_netOutPut.classLabelProbs);
    
    //方法三
//    CVPixelBufferRef cameraSampleBuffer;//摄像机拍摄回来的视频帧，直接调用下列方法，非常快速
//    [net predictionFromImage:cameraSampleBuffer error:&err];
    
}
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
                              };
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
