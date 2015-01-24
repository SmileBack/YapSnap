//
//  YSColorPicker.m
//  Pods
//
//  Created by Dan B on 1/23/15.
//
//

#import "YSColorPicker.h"

@implementation YSColorPicker

- (id)init
{
    if (self = [super init])
    {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self commonInit];
}

- (void)commonInit
{
    self.clipsToBounds = YES;
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"colormap"]];
    [self addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[image]|" options:0 metrics:nil views:@{@"image": imageView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[image]|" options:0 metrics:nil views:@{@"image": imageView}]];
}

#pragma mark - Touch Handling

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        [self updateHueSatWithMovement:[touch locationInView:self]];
    }
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        [self updateHueSatWithMovement:[touch locationInView:self]];
    }
}

- (void)updateHueSatWithMovement:(CGPoint) position { //important
    
    CGFloat currentHue = (position.x - CGRectGetMinX(self.frame))/CGRectGetWidth(self.frame);
    
    UIColor* selectedColor = [UIColor colorWithHue:currentHue
                                        saturation:1.0
                                        brightness:1.0
                                             alpha:1.0];
    
    CGFloat brightness;
    [selectedColor getHue:NULL saturation:NULL brightness:&brightness alpha:NULL];
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(selectedColor.CGColor));
    
    UIColor* newColor = nil;
    if (colorSpaceModel == kCGColorSpaceModelMonochrome)
    {
        newColor = [UIColor colorWithHue:0
                              saturation:1.0
                              brightness:1.0
                                   alpha:1.0];
    }
    else
    {
        newColor = [selectedColor copy];
    }
    
    // Call delegate with color
    if ([self.delegate respondsToSelector:@selector(colorPicker:didSelectColor:)])
    {
        [self.delegate colorPicker:self didSelectColor:newColor];
    }
}

@end
