
#import "XLsn0wCounter.h"
#import "XLsn0wiOSHeader.h"

#define JWONEPIXELS  (1.0/[UIScreen mainScreen].scale)
#define JWINTEGERTOSTRING(x) [NSString stringWithFormat:@"%ld",(long)x,nil]
#define JWUNIT [NSString stringWithFormat:@"%@",((self.valueUnit && self.valueUnit.length > 0) ? self.valueUnit : @"")]
#define JWINPUTTEXT(x) [NSString stringWithFormat:@"%@%@",JWINTEGERTOSTRING((x)),JWUNIT]

@interface XLsn0wCounter() <UITextFieldDelegate>

/** * 快速加减定时器 */
@property (nonatomic, strong) NSTimer *timer;
/** * 减按钮 */
@property (nonatomic, strong) UIButton *decreaseBtn;
/** * 加按钮 */
@property (nonatomic, strong) UIButton *increaseBtn;

@end

@implementation XLsn0wCounter

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupUI];
        
        if (CGRectIsEmpty(frame))
        {
            self.frame = CGRectMake(0, 0, 110, 30);
        }
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.minValue = 1;
    self.maxValue = NSIntegerMax;
    
    self.inputFont = [UIFont fontWithName:@"Arial" size:13];
    self.inputColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
    
    self.buttonTitleFont = [UIFont fontWithName:@"Arial" size:15];
    self.increaseTitle = @"+";
    self.decreaseTitle = @"-";
    
    self.longPressSpaceTime = CGFLOAT_MAX;
    
    self.decreaseHide = NO;
    
    self.shakeAnimation = NO;
}

#pragma mark - layoutSubviews
- (void)layoutSubviews {
    [super layoutSubviews];
    
//    self.inputTextField.frame = CGRectMake(selfHeight, 0, (selfWidth - selfHeight*2), selfHeight);
    [self.inputTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.centerY.mas_equalTo(self);
        make.width.mas_equalTo(55);
        make.height.mas_equalTo(self.height+4);
    }];
    
    self.increaseBtn.frame = CGRectMake(self.width-self.height, 0, self.height, self.height);
    
    if (self.decreaseHide && self.currentNumber < self.minValue) {
        self.decreaseBtn.frame = CGRectMake(self.width-self.height, 0, self.height, self.height);
        self.decreaseBtn.alpha = 0.0f;
    } else {
        self.decreaseBtn.frame = CGRectMake(0, 0, self.height, self.height);
    }
}

#pragma mark - Lazy loading
- (UITextField *)inputTextField {
    if (!_inputTextField) {
        self.inputTextField = [[UITextField alloc] init];
        _inputTextField.delegate = self;
        _inputTextField.textAlignment = NSTextAlignmentCenter;
        _inputTextField.keyboardType = UIKeyboardTypeNumberPad;
        _inputTextField.font = self.inputFont;
        _inputTextField.textColor = self.inputColor;
        _inputTextField.text = JWINPUTTEXT(self.minValue);
        [self addSubview:_inputTextField];
    }
    return _inputTextField;
}

- (UIButton *)decreaseBtn
{
    if (!_decreaseBtn)
    {
        self.decreaseBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _decreaseBtn.titleLabel.font = self.buttonTitleFont;
        [_decreaseBtn setTitleColor:[UIColor grayColor]
                           forState:UIControlStateNormal];
        [_decreaseBtn addTarget:self action:@selector(touchDown:)
               forControlEvents:UIControlEventTouchDown];
        [_decreaseBtn addTarget:self action:@selector(touchUp:)
               forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchUpInside|UIControlEventTouchCancel];
        [self addSubview:_decreaseBtn];
    }
    return _decreaseBtn;
}

- (UIButton *)increaseBtn
{
    if (!_increaseBtn)
    {
        self.increaseBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _increaseBtn.titleLabel.font = self.buttonTitleFont;
        [_increaseBtn setTitleColor:[UIColor grayColor]
                           forState:UIControlStateNormal];
        [_increaseBtn addTarget:self action:@selector(touchDown:)
               forControlEvents:UIControlEventTouchDown];
        [_increaseBtn addTarget:self action:@selector(touchUp:)
               forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchUpInside|UIControlEventTouchCancel];
        [self addSubview:_increaseBtn];

    }
    return _increaseBtn;
}

#pragma mark - Helper
- (void)touchUp:(id)sender
{
    if ([self.timer isValid])
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)touchDown:(id)sender
{
    [self.inputTextField resignFirstResponder];
    
    if (sender == self.increaseBtn)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:self.longPressSpaceTime
                                                  target:self
                                                selector:@selector(valueIncrease)
                                                userInfo:nil
                                                 repeats:YES];
    }
    else
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:self.longPressSpaceTime
                                                  target:self
                                                selector:@selector(valueDecrease)
                                                userInfo:nil
                                                 repeats:YES];
    }
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    [_timer fire];
}

- (void)valueIncrease
{
    [self checkInputAndUpdate];
    
    NSInteger tempValue = self.currentNumber + 1;
    if (tempValue <= self.maxValue)
    {
        // 如果原来是设置的'-'按钮是隐藏的，需要滚出来
        if (self.decreaseHide && tempValue == self.minValue)
        {
            // 滚动动画
            [self rotationAnimationMethod];
            
            [UIView animateWithDuration:0.3f animations:^{
                
                self.decreaseBtn.frame = CGRectMake(0, 0, self.height, self.height);
                self.decreaseBtn.alpha = 1;
                
            } completion:^(BOOL finished) {
                
                self.inputTextField.hidden = NO;
                self.inputTextField.alpha = 1.0f;
                
            }];
        }
        self.inputTextField.text = JWINPUTTEXT(tempValue);

        [self callbackAndIsIncrease:YES];

    }
    else
    {
        if (self.shakeAnimation)
        {
            [self shakeAnimationMethod];
        }
    }
}

- (void)valueDecrease
{
    [self checkInputAndUpdate];
    
    NSInteger tempValue = self.currentNumber - 1;

    if (tempValue >= self.minValue)
    {
        self.inputTextField.hidden = NO;
        self.inputTextField.text = JWINPUTTEXT(tempValue);

        [self callbackAndIsIncrease:NO];
    }
    else
    {
        // 如果设置了最小值就隐藏的功能，当减到最小时，要滚回去
        if (self.decreaseHide && tempValue < self.minValue)
        {
            [self rotationAnimationMethod];
            
            [UIView animateWithDuration:0.3f animations:^{
                
                self.decreaseBtn.alpha = 0.0f;
                self.decreaseBtn.frame = CGRectMake(self.width-self.height, 0, self.height, self.height);
                
            } completion:^(BOOL finished) {
                
            }];

            self.inputTextField.hidden = YES;
            self.inputTextField.text = JWINPUTTEXT(self.minValue-1);

            
            [self callbackAndIsIncrease:NO];
            
            return;
        }
        if (self.shakeAnimation)
        {
            [self shakeAnimationMethod];
        }
    }
}

- (void)checkInputAndUpdate
{
    NSString *tempMinValue = JWINPUTTEXT(self.minValue);
    NSString *tempMaxValue = JWINPUTTEXT(self.maxValue);
    
    NSString *tempValue = self.inputTextField.text;
    if (self.valueUnit && self.valueUnit.length > 0)
    {
        tempValue = [self.inputTextField.text stringByReplacingOccurrencesOfString:self.valueUnit withString:@""];
    }
    if ([tempValue isNotBlank] == NO ||
        self.currentNumber < self.minValue)
    {
        self.inputTextField.text = self.decreaseHide ? JWINPUTTEXT(self.minValue-1) : tempMinValue;
    }
    else if (self.currentNumber > self.maxValue)
    {
        self.inputTextField.text = tempMaxValue;
    }
}

- (void)callbackAndIsIncrease:(BOOL)isIncrease
{
    !self.valueChanged?:self.valueChanged(self.currentNumber, isIncrease);
}

#pragma mark - UITextField Delegate
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self checkInputAndUpdate];
    
    [self callbackAndIsIncrease:NO];
}

#pragma mark - animation method
- (void)shakeAnimationMethod
{
    CGFloat tempPositionX = self.layer.position.x;
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
    shakeAnimation.values = @[@(tempPositionX - 10),@(tempPositionX), @(tempPositionX + 10)];
    shakeAnimation.repeatCount = 3;
    shakeAnimation.duration = 0.07;
    shakeAnimation.autoreverses = YES;
    [self.layer addAnimation:shakeAnimation forKey:nil];
}

- (void)rotationAnimationMethod
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.toValue = @(M_PI*2);
    rotationAnimation.duration = 0.3f;
    rotationAnimation.fillMode = kCAFillModeForwards;
    rotationAnimation.removedOnCompletion = NO;
    [self.decreaseBtn.layer addAnimation:rotationAnimation forKey:nil];
}

#pragma mark - setter
- (void)setDecreaseHide:(BOOL)decreaseHide
{
    if (decreaseHide)
    {
        if (self.currentNumber <= self.minValue)
        {
            self.inputTextField.hidden = YES;
            self.inputTextField.text = JWINPUTTEXT(self.minValue-1);

            
            self.decreaseBtn.frame = CGRectMake(self.width-self.height, 0, self.height, self.height);
        }
        self.backgroundColor = [UIColor clearColor];
    }
    else
    {
        self.decreaseBtn.frame = CGRectMake(0, 0, self.height, self.height);
    }
    
    _decreaseHide = decreaseHide;
}

- (void)setEditing:(BOOL)editing
{
    _editing = editing;
    
    self.inputTextField.enabled = editing;
}

- (void)setMinValue:(NSInteger)minValue
{
    _minValue = minValue;
    
    self.inputTextField.text = JWINPUTTEXT(minValue);

    self.decreaseHide = self.decreaseHide;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    
    
    self.increaseBtn.layer.borderColor = borderColor.CGColor;
    self.increaseBtn.layer.borderWidth = JWONEPIXELS;
    
    self.decreaseBtn.layer.borderColor = borderColor.CGColor;
    self.decreaseBtn.layer.borderWidth = JWONEPIXELS;
}

- (void)setInputFont:(UIFont *)inputFont
{
    _inputFont = inputFont;
    
    self.inputTextField.font = inputFont;
}

- (void)setInputColor:(UIColor *)inputColor
{
    _inputColor = inputColor;
    
    self.inputTextField.textColor = inputColor;
}

- (void)setButtonTitleFont:(UIFont *)buttonTitleFont
{
    _buttonTitleFont = buttonTitleFont;
    
    self.increaseBtn.titleLabel.font = buttonTitleFont;
    self.decreaseBtn.titleLabel.font = buttonTitleFont;
}

- (void)setIncreaseTitle:(NSString *)increaseTitle
{
    _increaseTitle = increaseTitle;
    
    [self.increaseBtn setTitle:increaseTitle forState:UIControlStateNormal];
}

- (void)setIncreaseImage:(UIImage *)increaseImage
{
    _increaseImage = increaseImage;
    
    [self.increaseBtn setBackgroundImage:increaseImage forState:UIControlStateNormal];
    self.increaseTitle = @"";
}

- (void)setDecreaseTitle:(NSString *)decreaseTitle
{
    _decreaseTitle = decreaseTitle;
    
    [self.decreaseBtn setTitle:decreaseTitle forState:UIControlStateNormal];
}

- (void)setDecreaseImage:(UIImage *)decreaseImage
{
    _decreaseImage = decreaseImage;
    
    [self.decreaseBtn setBackgroundImage:decreaseImage forState:UIControlStateNormal];
    self.decreaseTitle = @"";
}

- (void)setCurrentNumber:(NSInteger)currentNumber
{
    if (self.decreaseHide && currentNumber < self.minValue)
    {
        self.inputTextField.hidden = YES;
        self.inputTextField.alpha = 0.0f;
        
        self.decreaseBtn.frame = CGRectMake(self.width-self.height, 0, self.height, self.height);
    }
    else
    {
        self.inputTextField.hidden = NO;
        self.inputTextField.alpha = 1.0f;
        
        self.decreaseBtn.frame = CGRectMake(0, 0, self.height, self.height);
    }
    
    self.inputTextField.text = JWINPUTTEXT(currentNumber);
    
    [self checkInputAndUpdate];
}

- (void)setValueUnit:(NSString *)valueUnit
{
    _valueUnit = valueUnit;
    
    self.inputTextField.text = JWINPUTTEXT(self.currentNumber);
}

#pragma mark - getter
- (NSInteger)currentNumber
{
    if (self.valueUnit && self.valueUnit.length > 0)
    {
        NSString *tempValue = [self.inputTextField.text stringByReplacingOccurrencesOfString:self.valueUnit withString:@""];
        return [tempValue integerValue];
    }
    else
    {
        return [self.inputTextField.text integerValue];
    }
}

@end

@implementation NSString (XLsn0wCounter)

- (BOOL)isNotBlank {
    NSCharacterSet *blank = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSInteger i = 0; i < self.length; ++i) {
        unichar c = [self characterAtIndex:i];
        if (![blank characterIsMember:c]) {
            return YES;
        }
    }
    return NO;
}

@end
