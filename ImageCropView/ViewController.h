//
//  ViewController.h
//  ImageCropView
//
//  Created by Ming Yang on 12/27/12.
//
//

#import <UIKit/UIKit.h>
#import "ImageCropView.h"


@interface ViewController : UIViewController {
    ImageCropView* imageCropView;
}

@property (nonatomic, retain) IBOutlet ImageCropView* imageCropView;

@end
