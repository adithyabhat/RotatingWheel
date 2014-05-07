//
//  RotaryWheel.h
//  Rotating wheel
//
//  Created by Adithya H on 31/01/13.
//

#import <UIKit/UIKit.h>

@protocol RotationProtocol <NSObject>

@optional
- (void) viewWillRotate:(UIView*)view;
- (void) view:(UIView*)rotatingView rotatedByAngle:(CGFloat)angle;
- (void) viewDidEndRotating:(UIView*)view;
- (void) viewDidEndDecelerating:(UIView*)view;
- (void) view:(UIView*)rotatingView rotationStoppedAtSection:(NSInteger)sectionNumber;

@end

@interface RotatingWheel : UIControl

@property (nonatomic) CGFloat filterTouchDistance;  //This is the distance from the center of the circle
@property (nonatomic) BOOL shouldDecelerate;
@property (nonatomic) int numberOfSectors;
@property (nonatomic) CGFloat currentAngle;

- (id) initWithView:(UIView*)viewToRotate
           delegate:(id)delegate;

//Rotates the wheel to an angle (in radians) w.r.t the positive X Axis
- (void)rotateToAngle:(CGFloat)angle animated:(BOOL)animated;

@end
