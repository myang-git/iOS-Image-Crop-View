//
//  MaskView.m
//
//  Created by Ming Yang on 7/7/12.
//

#import "ImageCropView.h"

static CGFloat const DEFAULT_MASK_ALPHA = 0.75;
static bool const square = NO;
float IMAGE_MIN_HEIGHT = 400;
float IMAGE_MIN_WIDTH = 400;

@interface ImageCropViewController(){
    CGRect _cropArea;
}

@end
#pragma mark ImageCropViewController implementation
@implementation ImageCropViewController

@synthesize delegate;
@synthesize cropView;

-(id)initWithImage:(UIImage*) image{
   self =  [super init];
    if (self){
        self.image = [image fixOrientation];
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self){
        UIView *contentView = [[UIView alloc] init];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentView.backgroundColor = [UIColor whiteColor];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancel:)];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(done:)];
        CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
        CGRect view = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - [[self navigationController] navigationBar].bounds.size.height - statusBarSize.height);
        self.cropView  = [[ImageCropView alloc] initWithFrame:view blurOn:self.blurredBackground];
        self.view = contentView;
        [contentView addSubview:cropView];
        [cropView setImage:self.image];
        if (_cropArea.size.width > 0) {
            self.cropView.cropAreaInImage = _cropArea;
        }
    }
}

- (IBAction)cancel:(id)sender
{
    
    if ([self.delegate respondsToSelector:@selector(ImageCropViewControllerDidCancel:)])
    {
        [self.delegate ImageCropViewControllerDidCancel:self];
    }
    
}

- (IBAction)done:(id)sender
{
    
    if ([self.delegate respondsToSelector:@selector(ImageCropViewControllerSuccess:didFinishCroppingImage:)])
    {
        UIImage *cropped;
        if (self.image != nil){
            CGRect CropRect = self.cropView.cropAreaInImage;
            CGImageRef imageRef = CGImageCreateWithImageInRect([self.image CGImage], CropRect) ;
            cropped = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        [self.delegate ImageCropViewControllerSuccess:self didFinishCroppingImage:cropped];
    }
    
}

- (void)setCropArea:(CGRect)cropArea {
    _cropArea = cropArea;
    if (self.cropView) {
        self.cropView.cropAreaInImage = _cropArea;
    }
}

- (CGRect)cropArea {
    if (self.cropView) {
        return self.cropView.cropAreaInImage;
    } else {
        return CGRectZero;
    }
}

@end


#pragma mark ControlPointView implementation

@implementation ControlPointView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.color = [UIColor colorWithRed:18.0/255.0 green:173.0/255.0 blue:251.0/255.0 alpha:1];
        self.opaque = NO;
    }
    return self;
}

- (void)setColor:(UIColor *)_color {
    [_color getRed:&red green:&green blue:&blue alpha:&alpha];
    [self setNeedsDisplay];
}

- (UIColor*)color {
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    CGContextFillEllipseInRect(context, rect);
}

@end

#pragma mark - MaskView implementation

@implementation ShadeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
        self.blurredImageView = [[UIImageView alloc] init];
    }
    return self;
}

- (void)setCropBorderColor:(UIColor *)_color {
    [_color getRed:&cropBorderRed green:&cropBorderGreen blue:&cropBorderBlue alpha:&cropBorderAlpha];
    [self setNeedsDisplay];
}

- (UIColor*)cropBorderColor {
    return [UIColor colorWithRed:cropBorderRed green:cropBorderGreen blue:cropBorderBlue alpha:cropBorderAlpha];
}

- (void)setCropArea:(CGRect)_cropArea {
    cropArea = _cropArea;
    [self setNeedsDisplay];
}

- (CGRect)cropArea {
    return cropArea;
}

- (void)setShadeAlpha:(CGFloat)_alpha {
    shadeAlpha = _alpha;
    [self setNeedsDisplay];
}

- (CGFloat)shadeAlpha {
    return shadeAlpha;
}

- (void)drawRect:(CGRect)rect
{
    CALayer* layer = self.blurredImageView.layer;
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextAddRect(c, self.cropArea);
    CGContextAddRect(c, rect);
    CGContextEOClip(c);
    CGContextSetFillColorWithColor(c, [UIColor blackColor].CGColor);
    CGContextFillRect(c, rect);
    UIImage* maskim = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CALayer* mask = [CALayer layer];
    mask.frame = rect;
    mask.contents = (id)maskim.CGImage;
    layer.mask = mask;
}

@end

#pragma mark - MaskImageView implementation

static CGFloat const DEFAULT_CONTROL_POINT_SIZE = 5;

CGRect SquareCGRectAtCenter(CGFloat centerX, CGFloat centerY, CGFloat size) {
    CGFloat x = centerX - size / 2.0;
    CGFloat y = centerY - size / 2.0;
    return CGRectMake(x, y, size, size);
}

@implementation ImageCropView

@synthesize cropAreaInImage;
@synthesize imageScale;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initViews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame blurOn:(BOOL)blurOn
{
    self = [super initWithFrame:frame];
    if (self) {
        self.blurred = blurOn;
        [self initViews];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self=[super initWithCoder:aDecoder]) {
        [self initViews];
    }
    return self;
}

- (void)initViews {
    CGRect subviewFrame = self.bounds;
    
    //the shade
    self.shadeView = [[ShadeView alloc] initWithFrame:subviewFrame];
    
    //the image
    imageView = [[UIImageView alloc] initWithFrame:subviewFrame];

    //control points
    controlPointSize = DEFAULT_CONTROL_POINT_SIZE;
    int initialCropAreaSize = self.frame.size.width / 5;
    CGPoint centerInView = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    topLeftPoint = [self createControlPointAt:SquareCGRectAtCenter(centerInView.x - initialCropAreaSize,
                                                                   centerInView.y - initialCropAreaSize, 
                                                                   controlPointSize)];
    
    bottomLeftPoint = [self createControlPointAt:SquareCGRectAtCenter(centerInView.x - initialCropAreaSize, 
                                                                      centerInView.y + initialCropAreaSize, 
                                                                      controlPointSize)];
    
    bottomRightPoint = [self createControlPointAt:SquareCGRectAtCenter(centerInView.x + initialCropAreaSize, 
                                                                       centerInView.y + initialCropAreaSize, controlPointSize) ];
    
    topRightPoint = [self createControlPointAt:SquareCGRectAtCenter(centerInView.x + initialCropAreaSize, 
                                                                    centerInView.y - initialCropAreaSize, controlPointSize)];
    
    //the "hole"
    CGRect cropArea = [self cropAreaFromControlPoints];
    cropAreaView = [[UIView alloc] initWithFrame:cropArea];
    cropAreaView.opaque = NO;
    cropAreaView.backgroundColor = [UIColor clearColor];
    UIPanGestureRecognizer* dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
    dragRecognizer.view.multipleTouchEnabled = YES;
    dragRecognizer.minimumNumberOfTouches = 1;
    dragRecognizer.maximumNumberOfTouches = 2;
    [self.viewForBaselineLayout addGestureRecognizer:dragRecognizer];
    
    [self addSubview:imageView];
    [self addSubview:self.shadeView];
    [self addSubview:self.shadeView.blurredImageView];
    [self addSubview:cropAreaView];
    [self addSubview:topRightPoint];
    [self addSubview:bottomRightPoint];
    [self addSubview:topLeftPoint];
    [self addSubview:bottomLeftPoint];
    
    PointsArray = [[NSArray alloc] initWithObjects:topRightPoint, bottomRightPoint, topLeftPoint, bottomLeftPoint, nil];
    
    self.maskAlpha = DEFAULT_MASK_ALPHA;
    
    imageFrameInView = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    imageView.frame = imageFrameInView;

}

- (ControlPointView*)createControlPointAt:(CGRect)frame {
    ControlPointView* point = [[ControlPointView alloc] initWithFrame:frame];
    return point;
}

- (CGRect)cropAreaFromControlPoints {
    CGFloat width = topRightPoint.center.x - topLeftPoint.center.x;
    CGFloat height = bottomRightPoint.center.y - topRightPoint.center.y;
    CGRect hole = CGRectMake(topLeftPoint.center.x, topLeftPoint.center.y, width, height);
    return hole;
}

- (CGRect)controllableAreaFromControlPoints {
    CGFloat width = topRightPoint.center.x - topLeftPoint.center.x - controlPointSize;
    CGFloat height = bottomRightPoint.center.y - topRightPoint.center.y - controlPointSize;
    CGRect hole = CGRectMake(topLeftPoint.center.x + controlPointSize / 2, topLeftPoint.center.y + controlPointSize / 2, width, height);
    return hole;
}

- (void)boundingBoxForTopLeft:(CGPoint)topLeft bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight topRight:(CGPoint)topRight {
    CGRect box = CGRectMake(topLeft.x - controlPointSize / 2, topLeft.y - controlPointSize / 2 , topRight.x - topLeft.x + controlPointSize , bottomRight.y - topRight.y + controlPointSize );
    //If not square - crop cropView =-)
    if (!square){
        box = CGRectIntersection(imageFrameInView, box);
    }
    
    if (CGRectContainsRect(imageFrameInView, box)) {
        bottomLeftPoint.center = CGPointMake(box.origin.x + controlPointSize / 2, box.origin.y + box.size.height - controlPointSize / 2);
        bottomRightPoint.center = CGPointMake(box.origin.x + box.size.width - controlPointSize / 2, box.origin.y + box.size.height - controlPointSize / 2);;
        topLeftPoint.center = CGPointMake(box.origin.x + controlPointSize / 2, box.origin.y + controlPointSize / 2);
        topRightPoint.center = CGPointMake(box.origin.x + box.size.width - controlPointSize / 2, box.origin.y + controlPointSize / 2);
    }
}

- (UIView*)checkHit:(CGPoint)point {
    UIView* view = cropAreaView;
    for (int i = 0; i < PointsArray.count; i++) {
        CGFloat x = [(ControlPointView *)PointsArray[i] center].x;
        CGFloat y = [(ControlPointView *)PointsArray[i] center].y;
        
        if (sqrt(pow((point.x - view.center.x), 2) + pow((point.y - view.center.y), 2)) >
            sqrt(pow((point.x - x), 2) + pow((point.y - y), 2)))
        {
            view = PointsArray[i];
        }
    }
    return view;
}

// Overriding this method to create a larger touch surface area without changing view
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
    CGRect frame = CGRectInset(cropAreaView.frame, -30, -30);
    return CGRectContainsPoint(frame, point) ? cropAreaView : nil;
}

- (void)handleDrag:(UIPanGestureRecognizer*)recognizer
{
    NSUInteger count = [recognizer numberOfTouches];
    if (recognizer.state == UIGestureRecognizerStateBegan || multiDragPoint.lastCount != count) {
        if (count > 1)
            [self prepMultiTouchPan:recognizer withCount:count];
        else
            [self prepSingleTouchPan:recognizer];
        multiDragPoint.lastCount = count;
        return;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        return; // no-op
    }
    
    if (count > 1) {
        // Transforms crop box based on the two dragPoints.
        for (int i = 0; i < count; i++) {
            dragPoint = i == 0 ? multiDragPoint.mainPoint : multiDragPoint.optionalPoint;
            [self beginCropBoxTransformForPoint:[recognizer locationOfTouch:i inView:self] atView:(i == 0 ? dragViewOne : dragViewTwo)];
            // Assign point centers that could have changed in previous transform
            multiDragPoint.optionalPoint.topLeftCenter = topLeftPoint.center;
            multiDragPoint.optionalPoint.bottomLeftCenter = bottomLeftPoint.center;
            multiDragPoint.optionalPoint.bottomRightCenter = bottomRightPoint.center;
            multiDragPoint.optionalPoint.topRightCenter = topRightPoint.center;
            multiDragPoint.optionalPoint.cropAreaCenter = cropAreaView.center;
        }
    } else {
        [self beginCropBoxTransformForPoint:[recognizer locationInView:self] atView:dragViewOne];
    }
    // Used to reset multiDragPoint when changing from 1 to 2 touches.
    multiDragPoint.lastCount = count;
}

/**
 * Records current values and points for multi-finger pan gestures
 * @params recognizer The pan gesuture with current point values
 * @params count The number of touches on view
 */
- (void)prepMultiTouchPan:(UIPanGestureRecognizer*)recognizer withCount:(NSUInteger)count
{
    for (int i = 0; i < count; i++) {
        if (i == 0) {
            dragViewOne = [self checkHit:[recognizer locationOfTouch:i inView:self]];
            multiDragPoint.mainPoint.dragStart = [recognizer locationOfTouch:i inView:self];
        } else {
            dragViewTwo = [self checkHit:[recognizer locationOfTouch:i inView:self]];
            multiDragPoint.optionalPoint.dragStart = [recognizer locationOfTouch:i inView:self];
        }
    }
    multiDragPoint.mainPoint.topLeftCenter = topLeftPoint.center;
    multiDragPoint.mainPoint.bottomLeftCenter = bottomLeftPoint.center;
    multiDragPoint.mainPoint.bottomRightCenter = bottomRightPoint.center;
    multiDragPoint.mainPoint.topRightCenter = topRightPoint.center;
    multiDragPoint.mainPoint.cropAreaCenter = cropAreaView.center;
}

/**
 * Records current values and points for single finger pan gestures
 * @params recognizer The pan gesuture with current point values
 */
- (void)prepSingleTouchPan:(UIPanGestureRecognizer*)recognizer
{
    dragViewOne = [self checkHit:[recognizer locationInView:self]];
    dragPoint.dragStart = [recognizer locationInView:self];
    dragPoint.topLeftCenter = topLeftPoint.center;
    dragPoint.bottomLeftCenter = bottomLeftPoint.center;
    dragPoint.bottomRightCenter = bottomRightPoint.center;
    dragPoint.topRightCenter = topRightPoint.center;
    dragPoint.cropAreaCenter = cropAreaView.center;
}

- (void)setCropAreaForViews:(CGRect)cropArea
{
    cropAreaView.frame = cropArea;
    // Create offset to make frame within imageView
    cropArea.origin.y = cropArea.origin.y - imageFrameInView.origin.y;
    cropArea.origin.x = cropArea.origin.x - imageFrameInView.origin.x;
    [self.shadeView setCropArea:cropArea];
}

- (void)beginCropBoxTransformForPoint:(CGPoint)location atView:(UIView*)view
{
    if (view == topLeftPoint) {
        [self handleDragTopLeft:location];
    } else if (view == bottomLeftPoint) {
        [self handleDragBottomLeft:location];
    } else if (view == bottomRightPoint) {
        [self handleDragBottomRight:location];
    } else if (view == topRightPoint) {
        [self handleDragTopRight:location];
    } else if (view == cropAreaView) {
        [self handleDragCropArea:location];
    }
    
    CGRect cropArea = [self cropAreaFromControlPoints];
    [self setCropAreaForViews:cropArea];
}

- (CGSize)deriveDisplacementFromDragLocation:(CGPoint)dragLocation draggedPoint:(CGPoint)draggedPoint oppositePoint:(CGPoint)oppositePoint {
    CGFloat dX = dragLocation.x - dragPoint.dragStart.x;
    CGFloat dY = dragLocation.y - dragPoint.dragStart.y;
    CGPoint tempDraggedPoint = CGPointMake(draggedPoint.x + dX, draggedPoint.y + dY);
    CGFloat width = (tempDraggedPoint.x - oppositePoint.x);
    CGFloat height = (tempDraggedPoint.y - oppositePoint.y);
    CGFloat size = fabs(width)>=fabs(height) ? width : height;
    CGFloat xDir = draggedPoint.x<=oppositePoint.x ? 1 : -1;
    CGFloat yDir = draggedPoint.y<=oppositePoint.y ? 1 : -1;
    CGFloat newX = 0, newY = 0;
    if (xDir>=0) {
        //on the right
        if(square)
        newX = oppositePoint.x - fabs(size);
        else
        newX = oppositePoint.x - fabs(width);
     }
    else {
        //on the left
    if(square )
        newX = oppositePoint.x + fabs(size);
    else
        newX = oppositePoint.x + fabs(width);
     }

    if (yDir>=0) {
        //on the top
    if(square)
        newY = oppositePoint.y - fabs(size);
    else
        newY = oppositePoint.y - fabs(height);
      }
    else {
        //on the bottom
    if(square)
        newY = oppositePoint.y + fabs(size);
    else
        newY = oppositePoint.y + fabs(height);
    }
    
    CGSize displacement = CGSizeMake(newX - draggedPoint.x, newY - draggedPoint.y);
    return displacement;
}

- (void)handleDragTopLeft:(CGPoint)dragLocation {
    CGSize disp = [self deriveDisplacementFromDragLocation:dragLocation draggedPoint:dragPoint.topLeftCenter oppositePoint:dragPoint.bottomRightCenter];
    CGPoint topLeft = CGPointMake(dragPoint.topLeftCenter.x + disp.width, dragPoint.topLeftCenter.y + disp.height);
    CGPoint topRight = CGPointMake(dragPoint.topRightCenter.x, dragPoint.topLeftCenter.y + disp.height);
    CGPoint bottomLeft = CGPointMake(dragPoint.bottomLeftCenter.x + disp.width, dragPoint.bottomLeftCenter.y);
    
    // Make sure that the new cropping area will not be smaller than the minimum image size
    CGFloat width = topRight.x - topLeft.x;
    CGFloat height = bottomLeft.y - topLeft.y;
    width = width * self.imageScale;
    height = height * self.imageScale;
    
    // If the crop area is too small, set the points at the minimum spacing.
    CGRect cropArea = [self cropAreaFromControlPoints];
    if (width >= IMAGE_MIN_WIDTH && height < IMAGE_MIN_HEIGHT) {
        topLeft.y = cropArea.origin.y + (((cropArea.size.height * self.imageScale) - IMAGE_MIN_HEIGHT) / self.imageScale);
        topRight.y = topLeft.y;
    } else if (width < IMAGE_MIN_WIDTH && height >= IMAGE_MIN_HEIGHT) {
        topLeft.x = cropArea.origin.x + (((cropArea.size.width * self.imageScale) - IMAGE_MIN_WIDTH) / self.imageScale);
        bottomLeft.x = topLeft.x;
    } else if (width < IMAGE_MIN_WIDTH && height < IMAGE_MIN_HEIGHT) {
        topLeft.x = cropArea.origin.x + (((cropArea.size.width * self.imageScale) - IMAGE_MIN_WIDTH) / self.imageScale);
        topLeft.y = cropArea.origin.y + (((cropArea.size.height * self.imageScale) - IMAGE_MIN_HEIGHT) / self.imageScale);
        topRight.y = topLeft.y;
        bottomLeft.x = topLeft.x;
    }
    
    [self boundingBoxForTopLeft:topLeft bottomLeft:bottomLeft bottomRight:dragPoint.bottomRightCenter topRight:topRight];
}
- (void)handleDragBottomLeft:(CGPoint)dragLocation {
    CGSize disp = [self deriveDisplacementFromDragLocation:dragLocation draggedPoint:dragPoint.bottomLeftCenter oppositePoint:dragPoint.topRightCenter];
    CGPoint bottomLeft = CGPointMake(dragPoint.bottomLeftCenter.x + disp.width, dragPoint.bottomLeftCenter.y + disp.height);
    CGPoint topLeft = CGPointMake(dragPoint.topLeftCenter.x + disp.width, dragPoint.topLeftCenter.y);
    CGPoint bottomRight = CGPointMake(dragPoint.bottomRightCenter.x, dragPoint.bottomRightCenter.y + disp.height);
    
    // Make sure that the new cropping area will not be smaller than the minimum image size
    CGFloat width = bottomRight.x - bottomLeft.x;
    CGFloat height = bottomLeft.y - topLeft.y;
    width = width * self.imageScale;
    height = height * self.imageScale;
    
    // If the crop area is too small, set the points at the minimum spacing.
    CGRect cropArea = [self cropAreaFromControlPoints];
    if (width >= IMAGE_MIN_WIDTH && height < IMAGE_MIN_HEIGHT) {
        bottomLeft.y = cropArea.origin.y + (IMAGE_MIN_HEIGHT / self.imageScale);
        bottomRight.y = bottomLeft.y;
    } else if (width < IMAGE_MIN_WIDTH && height >= IMAGE_MIN_HEIGHT) {
        bottomLeft.x = cropArea.origin.x + (((cropArea.size.width * self.imageScale) - IMAGE_MIN_WIDTH) / self.imageScale);
        topLeft.x = bottomLeft.x;
    } else if (width < IMAGE_MIN_WIDTH && height < IMAGE_MIN_HEIGHT) {
        bottomLeft.x = cropArea.origin.x + (((cropArea.size.width * self.imageScale) - IMAGE_MIN_WIDTH) / self.imageScale);
        bottomLeft.y = cropArea.origin.y + (IMAGE_MIN_HEIGHT / self.imageScale);
        topLeft.x = bottomLeft.x;
        bottomRight.y = bottomLeft.y;
    }
    
    [self boundingBoxForTopLeft:topLeft bottomLeft:bottomLeft bottomRight:bottomRight topRight:dragPoint.topRightCenter];
}

- (void)handleDragBottomRight:(CGPoint)dragLocation {
    CGSize disp = [self deriveDisplacementFromDragLocation:dragLocation draggedPoint:dragPoint.bottomRightCenter oppositePoint:dragPoint.topLeftCenter];
    CGPoint bottomRight = CGPointMake(dragPoint.bottomRightCenter.x + disp.width, dragPoint.bottomRightCenter.y + disp.height);
    CGPoint topRight = CGPointMake(dragPoint.topRightCenter.x + disp.width, dragPoint.topRightCenter.y);
    CGPoint bottomLeft = CGPointMake(dragPoint.bottomLeftCenter.x, dragPoint.bottomLeftCenter.y + disp.height);
    
    // Make sure that the new cropping area will not be smaller than the minimum image size
    CGFloat width = bottomRight.x - bottomLeft.x;
    CGFloat height = bottomRight.y - topRight.y;
    width = width * self.imageScale;
    height = height * self.imageScale;
    
    // If the crop area is too small, set the points at the minimum spacing.
    CGRect cropArea = [self cropAreaFromControlPoints];
    if (width >= IMAGE_MIN_WIDTH && height < IMAGE_MIN_HEIGHT) {
        bottomRight.y = cropArea.origin.y + (IMAGE_MIN_HEIGHT / self.imageScale);
        bottomLeft.y = bottomRight.y;
    } else if (width < IMAGE_MIN_WIDTH && height >= IMAGE_MIN_HEIGHT) {
        bottomRight.x = cropArea.origin.x + (IMAGE_MIN_WIDTH / self.imageScale);
        topRight.x = bottomRight.x;
    } else if (width < IMAGE_MIN_WIDTH && height < IMAGE_MIN_HEIGHT) {
        bottomRight.x = cropArea.origin.x + (IMAGE_MIN_WIDTH / self.imageScale);
        bottomRight.y = cropArea.origin.y + (IMAGE_MIN_HEIGHT / self.imageScale);
        topRight.x = bottomRight.x;
        bottomLeft.y = bottomRight.y;
    }

    [self boundingBoxForTopLeft:dragPoint.topLeftCenter bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight];
}

- (void)handleDragTopRight:(CGPoint)dragLocation {
    CGSize disp = [self deriveDisplacementFromDragLocation:dragLocation draggedPoint:dragPoint.topRightCenter oppositePoint:dragPoint.bottomLeftCenter];
    CGPoint topRight = CGPointMake(dragPoint.topRightCenter.x + disp.width, dragPoint.topRightCenter.y + disp.height);
    CGPoint topLeft = CGPointMake(dragPoint.topLeftCenter.x, dragPoint.topLeftCenter.y + disp.height);
    CGPoint bottomRight = CGPointMake(dragPoint.bottomRightCenter.x + disp.width, dragPoint.bottomRightCenter.y);
    
    // Make sure that the new cropping area will not be smaller than the minimum image size
    CGFloat width = topRight.x - topLeft.x;
    CGFloat height = bottomRight.y - topRight.y;
    width = width * self.imageScale;
    height = height * self.imageScale;
    
    // If the crop area is too small, set the points at the minimum spacing.
    CGRect cropArea = [self cropAreaFromControlPoints];
    if (width >= IMAGE_MIN_WIDTH && height < IMAGE_MIN_HEIGHT) {
        topRight.y = cropArea.origin.y + (((cropArea.size.height * self.imageScale) - IMAGE_MIN_HEIGHT) / self.imageScale);
        topLeft.y = topRight.y;
    } else if (width < IMAGE_MIN_WIDTH && height >= IMAGE_MIN_HEIGHT) {
        topRight.x = cropArea.origin.x + (IMAGE_MIN_WIDTH / self.imageScale);
        bottomRight.x = topRight.x;
    } else if (width < IMAGE_MIN_WIDTH && height < IMAGE_MIN_HEIGHT) {
        topRight.x = cropArea.origin.x + (IMAGE_MIN_WIDTH / self.imageScale);
        topRight.y = cropArea.origin.y + (((cropArea.size.height * self.imageScale) - IMAGE_MIN_HEIGHT) / self.imageScale);
        topLeft.y = topRight.y;
        bottomRight.x = topRight.x;
    }

    [self boundingBoxForTopLeft:topLeft bottomLeft:dragPoint.bottomLeftCenter bottomRight:bottomRight topRight:topRight];
}

- (void)handleDragCropArea:(CGPoint)dragLocation {
    CGFloat dX = dragLocation.x - dragPoint.dragStart.x;
    CGFloat dY = dragLocation.y - dragPoint.dragStart.y;
    
    CGPoint newTopLeft = CGPointMake(dragPoint.topLeftCenter.x + dX, dragPoint.topLeftCenter.y + dY);
    CGPoint newBottomLeft = CGPointMake(dragPoint.bottomLeftCenter.x + dX, dragPoint.bottomLeftCenter.y + dY);
    CGPoint newBottomRight = CGPointMake(dragPoint.bottomRightCenter.x + dX, dragPoint.bottomRightCenter.y + dY);
    CGPoint newTopRight = CGPointMake(dragPoint.topRightCenter.x + dX, dragPoint.topRightCenter.y + dY);

    CGFloat cropAreaWidth = dragPoint.topRightCenter.x - dragPoint.topLeftCenter.x;
    CGFloat cropAreaHeight = dragPoint.bottomLeftCenter.y - dragPoint.topLeftCenter.y;
    
    CGFloat minX = imageFrameInView.origin.x;
    CGFloat maxX = imageFrameInView.origin.x + imageFrameInView.size.width;
    CGFloat minY = imageFrameInView.origin.y;
    CGFloat maxY = imageFrameInView.origin.y + imageFrameInView.size.height;
    
    if (newTopLeft.x<minX) {
        newTopLeft.x = minX;
        newBottomLeft.x = minX;
        newTopRight.x = newTopLeft.x + cropAreaWidth;
        newBottomRight.x = newTopRight.x;
    }
    
    if(newTopLeft.y<minY) {
        newTopLeft.y = minY;
        newTopRight.y = minY;
        newBottomLeft.y = newTopLeft.y + cropAreaHeight;
        newBottomRight.y = newBottomLeft.y;
    }
    
    if (newBottomRight.x>maxX) {        
        newBottomRight.x = maxX;
        newTopRight.x = maxX;
        newTopLeft.x = newBottomRight.x - cropAreaWidth;
        newBottomLeft.x = newTopLeft.x;
    }
    
    if (newBottomRight.y>maxY) {
        newBottomRight.y = maxY;
        newBottomLeft.y = maxY;
        newTopRight.y = newBottomRight.y - cropAreaHeight;
        newTopLeft.y = newTopRight.y;
    }
    topLeftPoint.center = newTopLeft;
    bottomLeftPoint.center = newBottomLeft;
    bottomRightPoint.center = newBottomRight;
    topRightPoint.center = newTopRight;

}

- (void)setControlPointSize:(CGFloat)_controlPointSize {
    CGFloat halfSize = _controlPointSize;
    CGRect topLeftPointFrame = CGRectMake(topLeftPoint.center.x - halfSize, topLeftPoint.center.y - halfSize, controlPointSize, controlPointSize);
    CGRect bottomLeftPointFrame = CGRectMake(bottomLeftPoint.center.x - halfSize, bottomLeftPoint.center.y - halfSize, controlPointSize, controlPointSize);
    CGRect bottomRightPointFrame = CGRectMake(bottomRightPoint.center.x - halfSize, bottomRightPoint.center.y - halfSize, controlPointSize, controlPointSize);
    CGRect topRightPointFrame = CGRectMake(topRightPoint.center.x - halfSize, topRightPoint.center.y - halfSize, controlPointSize, controlPointSize);
    
    topLeftPoint.frame = topLeftPointFrame;
    bottomLeftPoint.frame = bottomLeftPointFrame;
    bottomRightPoint.frame = bottomRightPointFrame;
    topRightPoint.frame = topRightPointFrame;
    
    [self setNeedsDisplay];
}

- (CGFloat)controlPointSize {
    return controlPointSize;
}

- (void)setMaskAlpha:(CGFloat)alpha {
    self.shadeView.shadeAlpha = alpha;
}

- (CGFloat)maskAlpha {
    return self.shadeView.shadeAlpha;
}

- (CGRect)cropAreaInImage {
    CGRect _cropArea = self.cropAreaInView;
    CGRect r = CGRectMake((int)((_cropArea.origin.x - imageFrameInView.origin.x) * self.imageScale),
                          (int)((_cropArea.origin.y - imageFrameInView.origin.y) * self.imageScale),
                          (int)(_cropArea.size.width * self.imageScale),
                          (int)(_cropArea.size.height * self.imageScale));
    return r;
}

- (void)setCropAreaInImage:(CGRect)_cropAreaInImage {
    CGRect r = CGRectMake(_cropAreaInImage.origin.x/self.imageScale + imageFrameInView.origin.x,
                          _cropAreaInImage.origin.y/self.imageScale + imageFrameInView.origin.y,
                          _cropAreaInImage.size.width/self.imageScale,
                          _cropAreaInImage.size.height/self.imageScale);
    [self setCropAreaInView:r];
}

- (CGRect)cropAreaInView {
    CGRect cropArea = [self cropAreaFromControlPoints];
    return cropArea;
}

- (void)setCropAreaInView:(CGRect)cropArea {
    CGPoint topLeft = cropArea.origin;
    CGPoint bottomLeft = CGPointMake(cropArea.origin.x, cropArea.origin.y + cropArea.size.height);
    CGPoint bottomRight = CGPointMake(cropArea.origin.x + cropArea.size.width, cropArea.origin.y + cropArea.size.height);
    CGPoint topRight = CGPointMake(cropArea.origin.x + cropArea.size.width, cropArea.origin.y);
    topLeftPoint.center = topLeft;
    bottomLeftPoint.center = bottomLeft;
    bottomRightPoint.center = bottomRight;
    topRightPoint.center = topRight;
    
    [self setCropAreaForViews:cropArea];
    [self setNeedsDisplay];
}

- (void)setImage:(UIImage *)image {
    CGFloat frameWidth = self.frame.size.width;
    CGFloat frameHeight = self.frame.size.height;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    BOOL isPortrait = imageHeight / frameHeight > imageWidth/frameWidth;
    int x, y;
    int scaledImageWidth, scaledImageHeight;
    if (isPortrait) {
        imageScale = imageHeight / frameHeight;
        scaledImageWidth = imageWidth / imageScale;
        scaledImageHeight = frameHeight;
        x = (frameWidth - scaledImageWidth) / 2;
        y = 0;
    }
    else {
        imageScale = imageWidth / frameWidth;
        scaledImageWidth = frameWidth;
        scaledImageHeight = imageHeight / imageScale;
        x = 0;
        y = (frameHeight - scaledImageHeight) / 2;
    }
    imageFrameInView = CGRectMake(x, y, scaledImageWidth, scaledImageHeight);
    imageView.frame = imageFrameInView;
    imageView.image = image;
    
    /* prepare imageviews and their frame */
    self.shadeView.blurredImageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    self.shadeView.blurredImageView.clipsToBounds = YES;
    
    CGRect blurFrame;
    if (imageFrameInView.origin.x < 0 && (imageFrameInView.size.width - fabs(imageFrameInView.origin.x) >= 320)) {
        blurFrame = self.frame;
    } else {
        blurFrame = imageFrameInView;
    }
    imageView.frame = imageFrameInView;
    
    // blurredimageview is on top of shadeview so shadeview needs the same frame as imageView.
    self.shadeView.frame = imageFrameInView;
    self.shadeView.blurredImageView.frame = blurFrame;

    // perform image blur
    UIImage *blur;
    if (self.blurred) {
        blur = [image blurredImageWithRadius:30 iterations:1 tintColor:[UIColor blackColor]];
    } else {
        blur = [image blurredImageWithRadius:0 iterations:1 tintColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];
    }
    [self.shadeView.blurredImageView setImage:blur];
    
    //Special fix. If scaledImageWidth or scaledImageHeight < cropArea.width of cropArea.Height.
    [self boundingBoxForTopLeft:topLeftPoint.center bottomLeft:bottomLeftPoint.center bottomRight:bottomRightPoint.center topRight:topRightPoint.center];
    CGRect cropArea = [self cropAreaFromControlPoints];
    cropAreaView.frame = cropArea;
    cropArea.origin.y = cropArea.origin.y - imageFrameInView.origin.y;
    cropArea.origin.x = cropArea.origin.x - imageFrameInView.origin.x;
    [self.shadeView setCropArea:cropArea];
    
}

- (UIColor*)controlColor {
    return controlColor;
}

- (void)setControlColor:(UIColor *)_color {
    controlColor = _color;
    self.shadeView.cropBorderColor = _color;
    topLeftPoint.color = _color;
    bottomLeftPoint.color = _color;
    bottomRightPoint.color = _color;
    topRightPoint.color = _color;
}

- (void)setUserInteractionEnabled:(BOOL)_userInteractionEnabled {
    if (!_userInteractionEnabled) {
        [topLeftPoint setHidden:YES];
        [bottomLeftPoint setHidden:YES];
        [bottomRightPoint setHidden:YES];
        [topRightPoint setHidden:YES];
    }
    [super setUserInteractionEnabled:_userInteractionEnabled];
}

@end

@implementation UIImage (fixOrientation)

- (UIImage *)fixOrientation {
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
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
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
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
    CGImageRelease(cgimg);
    return img;
}
@end

