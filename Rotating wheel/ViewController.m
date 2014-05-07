//
//  ViewController.m
//  Rotating wheel
//
//  Created by Adithya H on 31/01/13.
//

#import "ViewController.h"
#import "RotatingWheel.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()
@property (nonatomic, strong) UIView *rotatingView;
@property (nonatomic, strong) RotatingWheel *wheel;
@end

@implementation ViewController
{
    CGFloat angle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializeRotatingViewWithType:1];
    
    self.wheel = [[RotatingWheel alloc] initWithView:self.rotatingView
                                                      delegate:self];
                                
    self.wheel.filterTouchDistance = CGRectGetWidth(self.rotatingView.bounds)/4;
    self.wheel.numberOfSectors = 5;
    self.wheel.shouldDecelerate = YES;
    
    self.wheel.center = self.view.center;
    self.wheel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.wheel];
}

- (void)initializeRotatingViewWithType:(NSInteger)type
{
    switch (type)
    {
        case 1:
            self.rotatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
            
            CGFloat angleSize = 2*M_PI/8;
            
            for (int i=0; i<8; i++)
            {
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
                label.backgroundColor = [UIColor redColor];
                label.text = [NSString stringWithFormat:@"%d",i+1];
                label.textAlignment = UITextAlignmentRight;
                
                label.layer.anchorPoint = CGPointMake(0.0f, 0.5f);
                label.layer.position = self.rotatingView.center;   //Postion Specifies the receiver’s position in the superlayer’s coordinate system.  Here point to be noted is that postion is set after the anchor point  is changed.
                //P.S Postion directly depends on the anchor point
                
                label.transform = CGAffineTransformMakeRotation(angleSize*i);
                label.tag = i+100;
                
                [self.rotatingView addSubview:label];
            }
            self.rotatingView.userInteractionEnabled = NO;
            break;
            
        default:
            self.rotatingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"color-wheel-300"]];
            break;
    }
}

- (IBAction)click:(id)sender
{
    angle += 45;
    [self.wheel rotateToAngle:angle animated:YES];
}

- (IBAction)reverseRotate:(id)sender
{
    angle -= 45;
    [self.wheel rotateToAngle:angle animated:YES];
}

#pragma mark - Delegate functions

- (void) viewWillRotate:(UIView*)view
{
    NSLog(@"viewWillRotate");
}

- (void) view:(UIView*)rotatingView rotatedByAngle:(CGFloat)angle
{
    NSLog(@"view:rotatedByAngle");
}

- (void) viewDidEndRotating:(UIView*)view
{
    NSLog(@"viewDidEndRotating");
}

- (void) viewDidEndDecelerating:(UIView*)view
{
    NSLog(@"viewDidEndDecelerating");
}

- (void) view:(UIView*)rotatingView rotationStoppedAtSection:(NSInteger)sectionNumber
{
    NSLog(@"view:rotationStoppedAtSection:");
}

@end
