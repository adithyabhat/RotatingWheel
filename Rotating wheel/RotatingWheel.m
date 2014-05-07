//
//  RotaryWheel.m
//  Rotating wheel
//
//  Created by Adithya H on 31/01/13.
//

#import "RotatingWheel.h"
#import <QuartzCore/QuartzCore.h>

#define MAX_VELOCITY 1000.0
#define MIN_VELOCITY 10.0
#define DECELERATION_RATE 0.97

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define radiansToDegrees(x) (180 * (x) / M_PI)

@interface RotatingWheel ()

@property BOOL isWheelDecelerating;
@property double animationVelocity;
@property double startTouchTime;
@property double endTouchTime;
@property double angleChange;
@property CGFloat sectorAngle;
@property CGFloat initialAngle;
@property CADisplayLink *displayLink;

@property (weak) id <RotationProtocol> delegate;
@property (weak) UIView *rotationView;

@end

@implementation RotatingWheel

#pragma mark - Public functions

- (id) initWithView:(UIView *)viewToRotate
           delegate:(id)delegate
{
    self = [super initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewToRotate.bounds), CGRectGetHeight(viewToRotate.bounds))];
    if (self)
    {
        _rotationView = viewToRotate;
        [self addSubview:_rotationView];
        
        _delegate = delegate;
        _currentAngle = 0;
    }
    return self;
}

- (void)rotateToAngle:(CGFloat)angle animated:(BOOL)animated
{
    [UIView animateWithDuration:(animated)? 0.4f : 0.0f
                          delay:0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         [self setCurrentAngle:angle];
                     }
                     completion:nil];
}

#pragma mark - Setter functions

- (void)setNumberOfSectors:(int)numberOfSections
{
    _numberOfSectors = numberOfSections;
    self.sectorAngle = 2 * M_PI / _numberOfSectors;
}

- (void)setCurrentAngle:(CGFloat)currentAngle
{
    [self transformByAngle:currentAngle - _currentAngle];
    _currentAngle = currentAngle;
}

#pragma mark - Helper function

/**
 Retunrs the angle (in radians) between and point and the positive X axis.
 */
CGFloat angleOfAPointFromPositiveXAxis(CGFloat y, CGFloat x)
{
    CGFloat theAngle = atan2f(y, x);  //atan2 is from -pi to pi. 1st quadrant x-axis to y-axis 0 to -pi/2, 2nd quadrant y-axis to x-axis -pi/2 to -pi, 3rd quadrant x-axis to y-axis -pi to pi/2 and 4th quadrant y-axis to x-axis pi/2 to 0. But the transform works in anti clockwise direction 0 to 2pi.
    
    // atan2f() returns values based on a unit circle. We want to convert into a full 360 degrees rather than use any negative values.
    if (theAngle < 0)
    {
        theAngle += 2*M_PI;
    }
	return theAngle;
}

- (CGFloat) distanceFromCenterOfPoint:(CGPoint)point
{
    CGPoint center = self.center;
    CGFloat dx = point.x - center.x;
    CGFloat dy = point.y - center.y;
    return sqrt(dx*dx + dy*dy);         //pythogoras theorem
}

/**
 The function is called from continueTrackingWithTouch:withEvent: function. The parameters set within this fucntion 
 helps in identifying the velocity of rotation.
 */
-(void)recordMovementWithAngle:(CGFloat)angle time:(NSTimeInterval)time
{    
    self.startTouchTime = self.endTouchTime;
    self.endTouchTime = time;
    
    if (angle > 100.0f)
    {
        angle -=360.0f;
    }
    else if (angle < -100.0f)
    {
        angle +=360.0f;
    }
    self.angleChange = angle;
}

CGFloat rotationVelocity(double startTouchTime, double endTouchTime, double angleChange)
{
    double velocity = 0.0;
    
    if (startTouchTime != endTouchTime)
    {
        velocity = angleChange/(endTouchTime - startTouchTime);     // Speed = distance/time (degrees/seconds)
    }
    return (velocity > MAX_VELOCITY) ? MAX_VELOCITY : ((velocity < -MAX_VELOCITY) ? -MAX_VELOCITY : velocity);
}

- (void) transformByAngle:(CGFloat)angleInDegrees
{
    self.transform = CGAffineTransformRotate(self.transform, degreesToRadians(-angleInDegrees));
}

- (BOOL)delegateRespondsToMethodWithName:(NSString*)methodName
{
    return (self.delegate != nil && [self.delegate respondsToSelector:NSSelectorFromString(methodName)]);
}

/**
 The function is called after the wheel completed rotation and deceleration.
 Applies some transform to the rotating wheel view in case required. This depends on the number of sections
 the wheel is divided into in turn the angle of each section. 
 */
- (void)reposition
{
    CGAffineTransform transform = self.transform;
    CGFloat rotatedAngle = angleOfAPointFromPositiveXAxis(transform.b, transform.a);
    CGFloat diff = fmodf(rotatedAngle, self.sectorAngle);
    
    [UIView animateWithDuration:0.4f animations:^{
        if (diff < (self.sectorAngle/2))
        {
            self.transform = CGAffineTransformRotate(self.transform, -diff);
        }
        else
        {
            self.transform = CGAffineTransformRotate(self.transform, (self.sectorAngle - diff));
        }
    }];
}

#pragma mark - Deceleration related functions

-(void)beginDeceleration
{
    double velocity = rotationVelocity(self.startTouchTime, self.endTouchTime, self.angleChange);
    
    if (velocity >= MIN_VELOCITY || velocity <= -MIN_VELOCITY)
    {
        self.isWheelDecelerating = YES;
        self.animationVelocity = velocity;
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(decelerationStep)];
        self.displayLink.frameInterval = 1;
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

-(void)decelerationStep
{
    double newVelocity = self.animationVelocity * DECELERATION_RATE;
    CGFloat angleToRotate = self.animationVelocity/60.0;                //60Hz is the screen refresh rate of iPhone
    
    if (angleToRotate <= 0.1 && angleToRotate >= -0.1)
    {
        [self endDeceleration];
//        [self reposition];
    }
    else
    {
        self.animationVelocity = newVelocity;
        [self transformByAngle:angleToRotate];
    }
}

-(void)endDeceleration
{
    self.isWheelDecelerating = NO;
    [self.displayLink invalidate], self.displayLink = nil;

    CGAffineTransform transform = self.transform;
    _currentAngle = radiansToDegrees(angleOfAPointFromPositiveXAxis(transform.b, transform.a));
    
    if ([self delegateRespondsToMethodWithName:@"viewDidEndDecelerating:"])
    {
        [self.delegate viewDidEndDecelerating:self.rotationView];
    }
    if ([self delegateRespondsToMethodWithName:@"view:rotationStoppedAtSection:"])
    {
        [self.delegate view:self.rotationView rotationStoppedAtSection:0];
    }
}

- (BOOL) isTouchesTooCloseToCenter:(CGPoint)touchPoint      //To filter out touches too close to the center
{
    BOOL returnVal = NO;
    CGFloat dist = [self distanceFromCenterOfPoint:touchPoint];
    
    if (dist < self.filterTouchDistance)
    {
        returnVal = YES;
    }
    return returnVal;
}


#pragma mark - UIControl delegates

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.isWheelDecelerating)
    {
        [self endDeceleration];
    }
    
    CGPoint touchPoint = [touch locationInView:[self superview]];
    if ([self isTouchesTooCloseToCenter:touchPoint])
    {
        return NO;
    }
    
    self.initialAngle = angleOfAPointFromPositiveXAxis(self.center.y - touchPoint.y, touchPoint.x - self.center.x) * 180.0f/M_PI;
    self.startTouchTime = self.endTouchTime = [NSDate timeIntervalSinceReferenceDate];  //Used for the deceleration part

    if ([self delegateRespondsToMethodWithName:@"viewWillRotate:"])
    {
        [self.delegate viewWillRotate:self.rotationView];
    }
    return YES;
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:[self superview]];
    CGFloat updatedAngle = angleOfAPointFromPositiveXAxis(self.center.y - touchPoint.y, touchPoint.x - self.center.x) * 180.0f/M_PI;
    CGFloat angleToRotate = updatedAngle - self.initialAngle;

    [self transformByAngle:angleToRotate];
    [self recordMovementWithAngle:angleToRotate time:[NSDate timeIntervalSinceReferenceDate]];
    
    self.initialAngle = updatedAngle;
    
    if ([self delegateRespondsToMethodWithName:@"view:rotatedByAngle:"])
    {
        [self.delegate view:self.rotationView rotatedByAngle:angleToRotate];
    }
    return YES;
}


- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.shouldDecelerate == YES)
    {
        [self beginDeceleration];
    }
    if ([self delegateRespondsToMethodWithName:@"viewDidEndRotating:"])
    {
        [self.delegate viewDidEndRotating:self.rotationView];
    }
}

@end
