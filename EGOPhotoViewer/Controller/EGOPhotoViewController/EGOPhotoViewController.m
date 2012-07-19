//
//  EGOPhotoController.m
//  EGOPhotoViewer
//
//  Created by Devin Doty on 1/8/10.
//  Copyright 2010 enormego. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOPhotoViewController.h"
#import "UINavigationItem+ColoredTitle.h"

@interface EGOPhotoViewController (Private)
- (void)loadScrollViewWithPage:(NSInteger)page;
- (void)layoutScrollViewSubviews;
- (void)setupScrollViewContentSize;
- (void)enqueuePhotoViewAtIndex:(NSInteger)theIndex;
- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (NSInteger)centerPhotoIndex;
- (void)setupToolbar;
- (void)setViewState;
@end


@implementation EGOPhotoViewController

@synthesize scrollView=_scrollView;
@synthesize photoSource=_photoSource; 
@synthesize photoViews=_photoViews;
@synthesize actionButtonHidden=_actionButtonHidden;

- (id)initWithPhotoSource:(id <EGOPhotoSource> )aSource andPhotoIndex:(NSInteger)index {
	_pageIndex = index;
	return [self initWithPhotoSource:aSource];
}


- (id)initWithPhotoSource:(id <EGOPhotoSource> )aSource{
	if ((self = [super init])) {
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleBarsNotification:) name:@"EGOPhotoViewToggleBars" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoViewDidFinishLoading:) name:@"EGOPhotoDidFinishLoading" object:nil];
		
		self.hidesBottomBarWhenPushed = YES;
		self.wantsFullScreenLayout = YES;		
		_photoSource = aSource;
		if (_pageIndex > 0) {
			//Do-Nothing
		}
		else {
			_pageIndex = 0;
		}
    _actionButtonHidden = NO;
		
	}
	
	return self;
}

#pragma mark -
#pragma mark View Controller Methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];
	self.wantsFullScreenLayout = YES;
	
	if (!_scrollView) {
		
		_scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
		_scrollView.delegate=self;
		_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		_scrollView.multipleTouchEnabled=YES;
		_scrollView.scrollEnabled=YES;
		_scrollView.directionalLockEnabled=YES;
		_scrollView.canCancelContentTouches=YES;
		_scrollView.delaysContentTouches=YES;
		_scrollView.clipsToBounds=YES;
		_scrollView.alwaysBounceHorizontal=YES;
		_scrollView.bounces=YES;
		_scrollView.pagingEnabled=YES;
		_scrollView.showsVerticalScrollIndicator=NO;
		_scrollView.showsHorizontalScrollIndicator=NO;
		_scrollView.backgroundColor = self.view.backgroundColor;
		[self.view addSubview:_scrollView];

	}
	
	if (!_captionView) {
		
		EGOPhotoCaptionView *view = [[EGOPhotoCaptionView alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, 1.0f)];
		[self.view addSubview:view];
		_captionView=view;
		
	}
	
	//  load photoviews lazily
	NSMutableArray *views = [[NSMutableArray alloc] init];
	for (unsigned i = 0; i < [self.photoSource numberOfPhotos]; i++) {
		[views addObject:[NSNull null]];
	}
	self.photoViews = views;


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if ([self.photoSource numberOfPhotos] == 1 && UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
		
		[self.navigationController setNavigationBarHidden:YES animated:NO];
		[self.navigationController setToolbarHidden:YES animated:NO];
		
		[self enqueuePhotoViewAtIndex:_pageIndex];
		[self loadScrollViewWithPage:_pageIndex];
		[self setViewState];
		
	}
#endif
	

}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];


    UIView *view = self.view;
    if (self.navigationController) {
        view = self.navigationController.view;
    }

    while (view != nil) {
        view = view.superview;
    }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
    if (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
#endif


    if(!_storedOldStyles) {
		_oldStatusBarSyle = [UIApplication sharedApplication].statusBarStyle;
		
		_oldNavBarTintColor = self.navigationController.navigationBar.tintColor;
		_oldNavBarStyle = self.navigationController.navigationBar.barStyle;
		_oldNavBarTranslucent = self.navigationController.navigationBar.translucent;
		
		_oldToolBarTintColor = self.navigationController.toolbar.tintColor;
		_oldToolBarStyle = self.navigationController.toolbar.barStyle;
		_oldToolBarTranslucent = self.navigationController.toolbar.translucent;
		_oldToolBarHidden = [self.navigationController isToolbarHidden];
		
		_storedOldStyles = YES;
	}	
	
	if ([self.navigationController isToolbarHidden] && ((([self.photoSource numberOfPhotos] > 1 || !_actionButtonHidden)) || ([self.photoSource numberOfPhotos] > 1))) {
		[self.navigationController setToolbarHidden:NO animated:YES];
	}

    self.navigationController.navigationBar.tintColor = nil;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;

    self.navigationController.toolbar.tintColor = nil;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.translucent = YES;

	
	[self setupToolbar];
	[self setupScrollViewContentSize];
	[self moveToPhotoAtIndex:_pageIndex animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	
	self.navigationController.navigationBar.barStyle = _oldNavBarStyle;
	self.navigationController.navigationBar.tintColor = _oldNavBarTintColor;
	self.navigationController.navigationBar.translucent = _oldNavBarTranslucent;
	
	[[UIApplication sharedApplication] setStatusBarStyle:_oldStatusBarSyle animated:YES];
	
	if(!_oldToolBarHidden) {
		
		if ([self.navigationController isToolbarHidden]) {
			[self.navigationController setToolbarHidden:NO animated:YES];
		}
		
		self.navigationController.toolbar.barStyle = _oldNavBarStyle;
		self.navigationController.toolbar.tintColor = _oldNavBarTintColor;
		self.navigationController.toolbar.translucent = _oldNavBarTranslucent;
		
	} else {
		[self.navigationController setToolbarHidden:_oldToolBarHidden animated:YES];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return (interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
	}

   	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	_rotating = YES;
	
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		CGRect rect = [[UIScreen mainScreen] bounds];
		self.scrollView.contentSize = CGSizeMake(rect.size.height * [self.photoSource numberOfPhotos], rect.size.width);
	}
	
	//  set side views hidden during rotation animation
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (count != _pageIndex) {
				[view setHidden:YES];
			}
		}
		count++;
	}
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			[view rotateToOrientation:toInterfaceOrientation];
		}
	}
		
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	
	[self setupScrollViewContentSize];
	[self moveToPhotoAtIndex:_pageIndex animated:NO];
	[self.scrollView scrollRectToVisible:((EGOPhotoImageView*)[self.photoViews objectAtIndex:_pageIndex]).frame animated:YES];
	
	//  unhide side views
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			[view setHidden:NO];
		}
	}
	_rotating = NO;
	
}

- (void)done:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)setupToolbar {
	
	if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
		if (self.modalPresentationStyle == UIModalPresentationFullScreen) {
			UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Fertig", @"done") style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
			self.navigationItem.rightBarButtonItem = doneButton;
		}
	} else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if (self.modalPresentationStyle == UIModalPresentationFullScreen) {
			UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Fertig", @"done") style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
			self.navigationItem.rightBarButtonItem = doneButton;
		}
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	}

	
	UIBarButtonItem *action = (_actionButtonHidden) ? [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] : [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonHit:)];
	UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	if ([self.photoSource numberOfPhotos] > 1) {
		
		UIBarButtonItem *fixedCenter = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
		fixedCenter.width = 80.0f;
		UIBarButtonItem *fixedLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
		fixedLeft.width = 40.0f;
		
		UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"egopv_left.png"] style:UIBarButtonItemStylePlain target:self action:@selector(moveBack:)];
		UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"egopv_right.png"] style:UIBarButtonItemStylePlain target:self action:@selector(moveForward:)];
		
		[self setToolbarItems:[NSArray arrayWithObjects:fixedLeft, flex, left, fixedCenter, right, flex, action, nil]];
		
		_rightButton = right;
		_leftButton = left;
		
		
	} else {
		[self setToolbarItems:[NSArray arrayWithObjects:flex, action, nil]];
	}
	
	_actionButton=action;
	
	
}

- (NSInteger)currentPhotoIndex{
	
	return _pageIndex;
	
}


#pragma mark -
#pragma mark Popver ContentSize Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{	
	[self setupScrollViewContentSize];
	[self layoutScrollViewSubviews];
}


#pragma mark -
#pragma mark Bar/Caption Methods

- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated{
	if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) return;

    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationFade];


}

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated{
	if (hidden&&_barsHidden) return;

		
	[self setStatusBarHidden:hidden animated:animated];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {

        if (animated) {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3f];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        }

        self.navigationController.navigationBar.alpha = hidden ? 0.0f : 1.0f;
        self.navigationController.toolbar.alpha = hidden ? 0.0f : 1.0f;

        if (animated) {
            [UIView commitAnimations];
        }

	} else {
		
		[self.navigationController setNavigationBarHidden:hidden animated:animated];
    
		// Set toolbar hidden if there is only one pic and the action menu is hidden
    if ([self.photoSource numberOfPhotos] <= 1 && _actionButtonHidden)
      [self.navigationController setToolbarHidden:YES animated:animated];
    else
      [self.navigationController setToolbarHidden:hidden animated:animated];
		
	}
	
	if (_captionView) {
		[_captionView setCaptionHidden:hidden];
	}
	
	_barsHidden=hidden;
	
}

- (void)toggleBarsNotification:(NSNotification*)notification{
	[self setBarsHidden:!_barsHidden animated:YES];
}


#pragma mark -
#pragma mark FullScreen Methods


- (CATransform3D)transformForCurrentOrientation{
	
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	switch (orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
			return CATransform3DMakeRotation((CGFloat) ((M_PI/180)*180), 0.0f, 0.0f, 1.0f);
		case UIInterfaceOrientationLandscapeRight:
			return CATransform3DMakeRotation((CGFloat) ((M_PI/180)*90), 0.0f, 0.0f, 1.0f);
		case UIInterfaceOrientationLandscapeLeft:
			return CATransform3DMakeRotation((CGFloat) ((M_PI/180)*-90), 0.0f, 0.0f, 1.0f);
		default:
			return CATransform3DIdentity;
	}
	
}

- (void)toggleFullScreen:(id)sender{
	
	_fullScreen = !_fullScreen;
	
	if (!_fullScreen) {
		
		NSInteger pageIndex = 0;
		if (self.modalViewController && [self.modalViewController isKindOfClass:[UINavigationController class]]) {
			UIViewController *controller = [((UINavigationController*)self.modalViewController) visibleViewController];
			if ([controller isKindOfClass:[self class]]) {
				pageIndex = [(EGOPhotoViewController*)controller currentPhotoIndex];
			}
		}		
		[self moveToPhotoAtIndex:pageIndex animated:NO];
		[self.navigationController dismissModalViewControllerAnimated:NO];
		
	}
	
	EGOPhotoImageView *_currentView = [self.photoViews objectAtIndex:_pageIndex];
	BOOL enabled = [UIView areAnimationsEnabled];
	[UIView setAnimationsEnabled:NO];
	[_currentView killScrollViewZoom];
	[UIView setAnimationsEnabled:enabled];
	UIImageView *_currentImage = _currentView.imageView;
	
	UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
	UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	backgroundView.layer.transform = [self transformForCurrentOrientation];
	[keyWindow addSubview:backgroundView];
	backgroundView.frame = [[UIScreen mainScreen] applicationFrame];
	_transferView = backgroundView;
	
	CGRect newRect = [self.view convertRect:_currentView.scrollView.frame toView:_transferView];
	UIImageView *_imageView = [[UIImageView alloc] initWithFrame:_fullScreen ? newRect : _transferView.bounds];	
	_imageView.contentMode = UIViewContentModeScaleAspectFit;
	[_imageView setImage:_currentImage.image];
	[_transferView addSubview:_imageView];
	
	self.scrollView.hidden = YES;
	
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
	animation.fromValue = _fullScreen ? (__bridge id)[UIColor clearColor].CGColor : (__bridge id)[UIColor blackColor].CGColor;
	animation.toValue = _fullScreen ? (__bridge id)[UIColor blackColor].CGColor : (__bridge id)[UIColor clearColor].CGColor;
	animation.removedOnCompletion = NO;
	animation.fillMode = kCAFillModeForwards;
	animation.duration = 0.4f;
	[_transferView.layer addAnimation:animation forKey:@"FadeAnimation"];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(fullScreenAnimationDidStop:finished:context:)];
	_imageView.frame = _fullScreen ? _transferView.bounds : newRect;
	[UIView commitAnimations];
	
}

- (void)fullScreenAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context{
	
	if (finished) {
		
		self.scrollView.hidden = NO;
		
		if (_transferView) {
			[_transferView removeFromSuperview];
			_transferView=nil;
		}
		
		if (_fullScreen) {
			
			BOOL enabled = [UIView areAnimationsEnabled];
			[UIView setAnimationsEnabled:NO];
			
			EGOPhotoViewController *controller = [[EGOPhotoViewController alloc] initWithPhotoSource:self.photoSource];
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			
			navController.modalPresentationStyle = UIModalPresentationFullScreen;
			[self.navigationController presentModalViewController:navController animated:NO];
			[controller moveToPhotoAtIndex:_pageIndex animated:NO];
			
			
			[UIView setAnimationsEnabled:enabled];
			
			UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"egopv_minimize_fullscreen_button.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleFullScreen:)];
			controller.navigationItem.rightBarButtonItem = button;
			
		}
		
	}
	
}



#pragma mark -
#pragma mark Photo View Methods

- (void)photoViewDidFinishLoading:(NSNotification*)notification{
	if (notification == nil) return;
	
	if ([[[notification object] objectForKey:@"photo"] isEqual:[self.photoSource photoAtIndex:[self centerPhotoIndex]]]) {
		if ([[[notification object] objectForKey:@"failed"] boolValue]) {
			if (_barsHidden) {
				//  image failed loading
				[self setBarsHidden:NO animated:YES];
			}
		} 
		[self setViewState];
	}
}

- (NSInteger)centerPhotoIndex{
	
	CGFloat pageWidth = self.scrollView.frame.size.width;
	return (NSInteger) (floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1);
	
}

- (void)moveForward:(id)sender{
	[self moveToPhotoAtIndex:[self centerPhotoIndex]+1 animated:NO];	
}

- (void)moveBack:(id)sender{
	[self moveToPhotoAtIndex:[self centerPhotoIndex]-1 animated:NO];
}

- (void)setViewState {	
	
	if (_leftButton) {
		_leftButton.enabled = !(_pageIndex-1 < 0);
	}
	
	if (_rightButton) {
		_rightButton.enabled = !(_pageIndex+1 >= [self.photoSource numberOfPhotos]);
	}
	
	if (_actionButton) {
		EGOPhotoImageView *imageView = [_photoViews objectAtIndex:[self centerPhotoIndex]];
		if ((NSNull*)imageView != [NSNull null]) {
			
			_actionButton.enabled = ![imageView isLoading];
			
		} else {
			
			_actionButton.enabled = NO;
		}
	}
	
	if ([self.photoSource numberOfPhotos] > 1) {
        [self.navigationItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"%i von %i", @"imageCounter"), _pageIndex+1, [self.photoSource numberOfPhotos]] withColor:[UIColor whiteColor]];
	} else {
		self.title = @"";
	}
	
	if (_captionView) {
		[_captionView setCaptionText:[[self.photoSource photoAtIndex:_pageIndex] caption] hidden:NO];
	}
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
			
	if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)] && [self.photoSource numberOfPhotos] == 1) {
		
		EGOPhotoImageView *imageView = [_photoViews objectAtIndex:[self centerPhotoIndex]];
		if ((NSNull*)imageView != [NSNull null]) {
			self.contentSizeForViewInPopover = [imageView sizeForPopover];
		}
		
	}
	
#endif
	
}

- (void)moveToPhotoAtIndex:(NSInteger)index animated:(BOOL)animated {
	NSAssert(index < [self.photoSource numberOfPhotos] && index >= 0, @"Photo index passed out of bounds");
	
	_pageIndex = index;
	[self setViewState];

	[self enqueuePhotoViewAtIndex:index];
	
	[self loadScrollViewWithPage:index-1];
	[self loadScrollViewWithPage:index];
	[self loadScrollViewWithPage:index+1];
	
	
	[self.scrollView scrollRectToVisible:((EGOPhotoImageView*)[self.photoViews objectAtIndex:index]).frame animated:animated];
	
	if ([[self.photoSource photoAtIndex:_pageIndex] didFail]) {
		[self setBarsHidden:NO animated:YES];
	}
	
	//  reset any zoomed side views
	if (index + 1 < [self.photoSource numberOfPhotos] && (NSNull*)[self.photoViews objectAtIndex:index+1] != [NSNull null]) {
		[((EGOPhotoImageView*)[self.photoViews objectAtIndex:index+1]) killScrollViewZoom];
	} 
	if (index - 1 >= 0 && (NSNull*)[self.photoViews objectAtIndex:index-1] != [NSNull null]) {
		[((EGOPhotoImageView*)[self.photoViews objectAtIndex:index-1]) killScrollViewZoom];
	} 	
	
}

- (void)layoutScrollViewSubviews{
	
	NSInteger _index = [self currentPhotoIndex];
	
	for (NSInteger page = _index -1; page < _index+3; page++) {
		
		if (page >= 0 && page < [self.photoSource numberOfPhotos]){
			
			CGFloat originX = self.scrollView.bounds.size.width * page;
			
			if (page < _index) {
				originX -= EGOPV_IMAGE_GAP;
			} 
			if (page > _index) {
				originX += EGOPV_IMAGE_GAP;
			}
			
			if ([self.photoViews objectAtIndex:page] == [NSNull null] || !((UIView*)[self.photoViews objectAtIndex:page]).superview){
				[self loadScrollViewWithPage:page];
			}
			
			EGOPhotoImageView *_photoView = (EGOPhotoImageView*)[self.photoViews objectAtIndex:page];
			CGRect newframe = CGRectMake(originX, 0.0f, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
			
			if (!CGRectEqualToRect(_photoView.frame, newframe)) {	
				
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.1];
				_photoView.frame = newframe;
				[UIView commitAnimations];
			
			}
			
		}
	}
	
}

- (void)setupScrollViewContentSize{
	
	CGFloat toolbarSize = self.navigationController.toolbar.frame.size.height;
	
	CGSize contentSize = self.view.bounds.size;
	contentSize.width = (contentSize.width * [self.photoSource numberOfPhotos]);
	
	if (!CGSizeEqualToSize(contentSize, self.scrollView.contentSize)) {
		self.scrollView.contentSize = contentSize;
	}
	
	_captionView.frame = CGRectMake(0.0f, self.view.bounds.size.height - (toolbarSize + 40.0f), self.view.bounds.size.width, 40.0f);

}

- (void)enqueuePhotoViewAtIndex:(NSInteger)theIndex{
	
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (count > theIndex+1 || count < theIndex-1) {
				[view prepareForReusue];
				[view removeFromSuperview];
			} else {
				view.tag = 0;
			}
			
		} 
		count++;
	}	
	
}

- (EGOPhotoImageView*)dequeuePhotoView{
	
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (view.superview == nil) {
				view.tag = count;
				return view;
			}
		}
		count ++;
	}	
	return nil;
	
}

- (void)loadScrollViewWithPage:(NSInteger)page {
	
    if (page < 0) return;
    if (page >= [self.photoSource numberOfPhotos]) return;
	
	EGOPhotoImageView * photoView = [self.photoViews objectAtIndex:page];
	if ((NSNull*)photoView == [NSNull null]) {
		
		photoView = [self dequeuePhotoView];
		if (photoView != nil) {
			[self.photoViews exchangeObjectAtIndex:photoView.tag withObjectAtIndex:page];
			photoView = [self.photoViews objectAtIndex:page];
		}
		
	}
	
	if (photoView == nil || (NSNull*)photoView == [NSNull null]) {
		
		photoView = [[EGOPhotoImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height)];
		[self.photoViews replaceObjectAtIndex:page withObject:photoView];
		
	} 
	
	[photoView setPhoto:[self.photoSource photoAtIndex:page]];
	
    if (photoView.superview == nil) {
		[self.scrollView addSubview:photoView];
	}
	
	CGRect frame = self.scrollView.frame;
	NSInteger centerPageIndex = _pageIndex;
	CGFloat xOrigin = (frame.size.width * page);
	if (page > centerPageIndex) {
		xOrigin = (frame.size.width * page) + EGOPV_IMAGE_GAP;
	} else if (page < centerPageIndex) {
		xOrigin = (frame.size.width * page) - EGOPV_IMAGE_GAP;
	}
	
	frame.origin.x = xOrigin;
	frame.origin.y = 0;
	photoView.frame = frame;
}


#pragma mark -
#pragma mark UIScrollView Delegate Methods


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
	NSInteger _index = [self centerPhotoIndex];
	if (_index >= [self.photoSource numberOfPhotos] || _index < 0) {
		return;
	}
	
	if (_pageIndex != _index && !_rotating) {

		[self setBarsHidden:YES animated:YES];
		_pageIndex = _index;
		[self setViewState];
		
		if (![scrollView isTracking]) {
			[self layoutScrollViewSubviews];
		}
		
	}
		
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	NSInteger _index = [self centerPhotoIndex];
	if (_index >= [self.photoSource numberOfPhotos] || _index < 0) {
		return;
	}
	
	[self moveToPhotoAtIndex:_index animated:YES];

}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
	[self layoutScrollViewSubviews];
}


#pragma mark -
#pragma mark Actions

- (void)doneSavingImage{
	NSLog(@"done saving image");
}

- (void)savePhoto{
	
	UIImageWriteToSavedPhotosAlbum(((EGOPhotoImageView*)[self.photoViews objectAtIndex:_pageIndex]).imageView.image, nil, nil, nil);
	
}

- (void)copyPhoto{
	
	[[UIPasteboard generalPasteboard] setData:UIImagePNGRepresentation(((EGOPhotoImageView*)[self.photoViews objectAtIndex:_pageIndex]).imageView.image) forPasteboardType:@"public.png"];
	
}

- (void)emailPhoto{
	
	MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
	[mailViewController setSubject:@"Share Foto"];
	[mailViewController addAttachmentData:[NSData dataWithData:UIImagePNGRepresentation(((EGOPhotoImageView*)[self.photoViews objectAtIndex:_pageIndex]).imageView.image)] mimeType:@"image/png" fileName:@"Photo.png"];
	mailViewController.mailComposeDelegate = self;

	if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
		mailViewController.modalPresentationStyle = UIModalPresentationPageSheet;
	}
	
	[self presentModalViewController:mailViewController animated:YES];
	
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
	
	[self dismissModalViewControllerAnimated:YES];
	
	NSString *mailError = nil;
	
	switch (result) {
		case MFMailComposeResultSent: ; break;
		case MFMailComposeResultFailed: mailError = @"Senden fehlgeschlagen, bitte versuchen Sie es erneut...";
			break;
		default:
			break;
	}
	
	if (mailError != nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:mailError delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}
	
}


#pragma mark -
#pragma mark UIActionSheet Methods

- (void)actionButtonHit:(id)sender{
	
	UIActionSheet *actionSheet;
	
	if ([MFMailComposeViewController canSendMail]) {

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Speichern", @"Kopieren", @"E-Mail", nil];
		} else {
			actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Abbrechen" destructiveButtonTitle:nil otherButtonTitles:@"Speichern", @"Kopieren", @"E-Mail", nil];
		}
	} else {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Speichern", @"Kopieren", nil];
		} else {
			actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Abbrechen" destructiveButtonTitle:nil otherButtonTitles:@"Speichern", @"Kopieren", nil];
		}
		
	}
	
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	actionSheet.delegate = self;
	
	[actionSheet showInView:self.view];
	[self setBarsHidden:YES animated:YES];
	
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	
	[self setBarsHidden:NO animated:YES];
	
	if (buttonIndex == actionSheet.cancelButtonIndex) {
		return;
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
		[self savePhoto];
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
		[self copyPhoto];	
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
		[self emailPhoto];	
	}
}


#pragma mark -
#pragma mark Memory

- (void)didReceiveMemoryWarning{
    self.photoViews=nil;
   	self.scrollView=nil;
   	_captionView=nil;
}

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_captionView=nil;
	_oldToolBarTintColor = nil;
	_oldNavBarTintColor = nil;
	
}


@end