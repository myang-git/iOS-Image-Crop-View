iOS-Image-Crop-View
===================

A view allowing user to specify a rectangle area in an image. The user can drag the corner to 
resize it, move the entire bounding box, or use 2 fingers like a pinch gesture to move and resize the bounding box. The color and size of the dots on the corner can be customized.

Screenshot
===================
![alt text](https://raw.github.com/myang-git/iOS-Image-Crop-View/master/ImageCropViewScreenShot.png)

[Demo Video](https://raw.github.com/myang-git/iOS-Image-Crop-View/master/demo.mov)

How to Use
===================
Very easy! It is created to be a drop-in component, so no static library, no extra dependencies.
Just copy <code>ImageCropView.h</code> and <code>ImageCropView.m</code> to your project, 
and implement ImageCropViewControllerDelegate protocol.

Use it like UIImagePicker:
``` objective-c
- (void)cropImage:(UIImage *)image{
	ImageCropViewController *controller = [[ImageCropViewController alloc] initWithImage:image];
	controller.delegate = self;
	[[self navigationController] pushViewController:controller animated:YES];
}
```
``` objective-c
- (void)ImageCropViewController:(ImageCropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage{
   image = croppedImage;
   imageView.image = croppedImage;
   [[self navigationController] popViewControllerAnimated:YES];
}
```
``` objective-c
- (void)ImageCropViewControllerDidCancel:(ImageCropViewController *)controller{
    imageView.image = image;
    [[self navigationController] popViewControllerAnimated:YES];
}
```
### Optional Blurring
Using FXBlurView, you can now blur the parts of the image outside the crop area. This is not for blurring the final cropped image. Just set the `blurredBackground` property in the same place you set the delegate, like so:
``` objective-c
controller.blurredBackground = YES;
```
### Override control point size
Default point size is 5.0 . If you want to override it, you can do
``` objective-c
controller.pointSize = 9.5;
```
### Minimum Image Size
To set the minimum height and width of a cropped image, simply change the `IMAGE_MIN_HEIGHT` and `IMAGE_MIN_WIDTH` variables at the top of `ImageCropView.m`.

The project comes with a working example (as target ***ImageCropView***) to demostrate the usage. 

License
===================

Copyright (C) 2012 Ming Yang

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
