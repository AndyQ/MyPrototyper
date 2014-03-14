//
//  FlowStructureViewController.m
//  BALearningEditor
//
//  Created by Andy Qua on 07/03/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ProjectStructureViewController.h"
#import "Project.h"
#import "Node.h"
#import "ImageDetails.h"

#define ZOOM_STEP 1.5

@interface ProjectStructureViewController () <UIScrollViewDelegate>
{
    Node *rootNode;
    
    UIImageView *zoomImageView;
    CGRect zoomOrigFrame;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;

@end

@implementation ProjectStructureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

//    [self downloadImage];
    
    rootNode = [self loadDotFile];
    UIImage *image = [self generateImageFromNode:rootNode];

    [self setupScrollViewWithImage:image];
    
    self.imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    
    [doubleTap setNumberOfTapsRequired:2];
    [twoFingerTap setNumberOfTouchesRequired:2];
    
    [self.imageView addGestureRecognizer:doubleTap];
    [self.imageView addGestureRecognizer:twoFingerTap];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(processLongTouch:)];
    [longPress setMinimumPressDuration:0.25];
    [self.imageView addGestureRecognizer:longPress];
}

- (void) setupScrollViewWithImage:(UIImage *)image
{
    UIScrollView *scrollView;
    UIImageView *imageView;
    NSDictionary *viewsDictionary;
    
    // Create the scroll view and the image view.
    scrollView  = [[UIScrollView alloc] init];
    imageView = [[UIImageView alloc] init];
    
    // Add an image to the image view.
    [imageView setImage:image];
    [imageView sizeToFit];
    
    // Add the scroll view to our view.
    [self.view addSubview:scrollView];
    
    // Add the image view to the scroll view.
    [scrollView addSubview:imageView];
    
    // Set the translatesAutoresizingMaskIntoConstraints to NO so that the views autoresizing mask is not translated into auto layout constraints.
    scrollView.translatesAutoresizingMaskIntoConstraints  = NO;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Set the constraints for the scroll view and the image view.
    viewsDictionary = NSDictionaryOfVariableBindings(scrollView, imageView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics: 0 views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView]|" options:0 metrics: 0 views:viewsDictionary]];
    [scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics: 0 views:viewsDictionary]];
    [scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics: 0 views:viewsDictionary]];
    

    self.scrollView = scrollView;
    self.imageView = imageView;
    
    self.scrollView.delegate = self;

}

- (void) viewWillAppear:(BOOL)animated
{
    self.scrollView.minimumZoomScale=0.1;
    self.scrollView.maximumZoomScale=2.0;
    self.scrollView.zoomScale = 0.8;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.scrollView.contentOffset = CGPointMake( self.scrollView.contentSize.width/2, 0 );
    });
}


- (void) downloadImage
{
    dispatch_queue_t downloadQueue = dispatch_queue_create("downloadStructureQueue", NULL);

    dispatch_async(downloadQueue, ^{
        NSString *urlStr = [[self.project generateDotFile] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSData * imageData = [NSData dataWithContentsOfURL:url];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage imageWithData:imageData];
            self.imageView.image = image;
            [self.imageView sizeToFit];
            self.scrollView.contentSize = image.size;
        });
    });

}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    [scrollView setZoomScale:scale+0.01 animated:NO];
    [scrollView setZoomScale:scale animated:NO];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Tapping and touching handles


- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
    // double tap zooms in
    float newScale = [self.scrollView zoomScale] * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)handleTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer {
    // two-finger tap zooms out
    float newScale = [self.scrollView zoomScale] / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)processLongTouch:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [gestureRecognizer locationInView:self.imageView];
        
        // Find node that matches this point
        Node *node = [self getNodeAtPoint:point fromNode:rootNode];
        if ( node != nil )
        {
            int nodeIndex = [node.nodeNr intValue];
            if ( nodeIndex == -1 )
                return;
            ImageDetails *imageDetails = self.project[nodeIndex];
            UIImage *image = [imageDetails getImage];
            
            zoomOrigFrame = CGRectInset( node.frame, 5, 5 );
            
            zoomOrigFrame.origin.x *= self.scrollView.zoomScale;
            zoomOrigFrame.origin.y *= self.scrollView.zoomScale;
            zoomOrigFrame.size.width *= self.scrollView.zoomScale;
            zoomOrigFrame.size.height *= self.scrollView.zoomScale;

            zoomOrigFrame.origin.x -= self.scrollView.contentOffset.x;
            zoomOrigFrame.origin.y -= self.scrollView.contentOffset.y;

            zoomImageView = [[UIImageView alloc] initWithImage:image];
            zoomImageView.layer.borderWidth = 1;
            zoomImageView.layer.borderColor = [UIColor blackColor].CGColor;
            
            zoomImageView.frame = zoomOrigFrame;
            [self.view addSubview:zoomImageView];
            [UIView animateWithDuration:0.25 animations:^{
                
                CGFloat w = MIN( self.view.bounds.size.width, self.view.bounds.size.height) - 30;
                CGFloat x = 15;
                CGFloat y = self.view.bounds.size.height/2 - w/2;
                CGRect f = CGRectMake( x, y, w, w );
                
                zoomImageView.frame = f;
            }];
        }
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [UIView animateWithDuration:0.25 animations:^{
            zoomImageView.frame = zoomOrigFrame;
        } completion:^(BOOL finished) {
            [zoomImageView removeFromSuperview];
            zoomImageView = nil;
        }];
    }

}

- (Node *) getNodeAtPoint:(CGPoint)point fromNode:(Node *)node
{
    Node *ret = nil;
    if ( CGRectContainsPoint(node.frame, point ) )
        ret = node;
    else
    {
        // Check children
        for ( Node *n in node.children )
        {
            ret = [self getNodeAtPoint:point fromNode:n];
            if ( ret != nil )
                break;
        }
    }
    
    return ret;
}



#pragma mark Utility methods

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [self.scrollView frame].size.height / scale;
    zoomRect.size.width  = [self.scrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

#pragma - Node Handling

- (Node *) loadDotFile
{
    NSString *dot = [self.project generateDotFile];

//  dot = @"0 -> 1;0 -> 2;0 -> -1;1 -> 2;2 -> 3;2 -> 10;2 -> 11;2 -> 42;3 -> 41;3 -> 9;3 -> 4;3 -> 5;3 -> 6;3 -> 7;3 -> 8;4 -> 2;5 -> 2;6 -> 2;7 -> 2;8 -> 2;9 -> 2;10 -> 2;11 -> 12;11 -> 10;12 -> 14;14 -> 15;15 -> 16;15 -> 2;16 -> 17;16 -> 2;17 -> 18;18 -> 19;19 -> 22;20 -> 21;21 -> 23;22 -> 20;22 -> 2;23 -> 24;23 -> 2;24 -> 25;24 -> 2;25 -> 26;26 -> 27;27 -> 28;28 -> 29;29 -> 30;30 -> 31;31 -> 32;32 -> 33;33 -> 34;34 -> 35;35 -> 37;37 -> 38;38 -> 39;39 -> 40;40 -> 2;41 -> 2;42 -> 10;42 -> 43;43 -> 44;44 -> 45;45 -> 46;46 -> 47;47 -> 48;47 -> 49;48 -> 47;49 -> -1;49 -> 2;";
    
    //    dot = @"0 -> 1;0 -> 2;0 -> -1;1 -> 2;2 -> 3;2 -> 10;2 -> 11;2 -> 42;3 -> 41;3 -> 9;3 -> 4;3 -> 5;3 -> 6;3 -> 7;3 -> 8;11 -> 12;11 -> 10;12 -> 14;14 -> 15;15 -> 16;16 -> 17;17 -> 18;18 -> 19;19 -> 22;20 -> 21;21 -> 23;22 -> 20;23 -> 24;24 -> 25;25 -> 26;26 -> 27;27 -> 28;28 -> 29;29 -> 30;30 -> 31;31 -> 32;32 -> 33;33 -> 34;34 -> 35;35 -> 37;37 -> 38;38 -> 39;39 -> 40;42 -> 10;42 -> 43;43 -> 44;44 -> 45;45 -> 46;46 -> 47;47 -> 48;47 -> 49;";
    
    //    dot = @"0 -> 1;0 -> 2;1 -> 2;2 -> 3;";
    //    dot = @"0 -> 1;1 -> 2;2 -> 0;";
    
    // Remove initial diagraph bit
    int start = [dot rangeOfString:@"{"].location;
    dot = [dot substringFromIndex:start+1];
    int end = [dot rangeOfString:@"}"].location;
    dot = [dot substringToIndex:end];
    
    NSArray *items = [dot componentsSeparatedByString:@";"];
    
    NSMutableDictionary *nodeDict = [NSMutableDictionary dictionary];
    Node *root = nil;
    for ( NSString *item in items )
    {
        NSArray *vals = [item componentsSeparatedByString:@" -> "];
        if ( vals.count != 2 )
            continue;
        
        NSString *from = vals[0];
        NSString *to = vals[1];
        
        Node *parent = nodeDict[from];
        
        if ( parent == nil )
        {
            parent = [[Node alloc] init];
            parent.frame = (CGRect){{0, 50}, {BLOCK_WIDTH,BLOCK_HEIGHT}};
            //            parent.parentView = self.drawView;
            parent.nodeNr = from;
            parent.level = 0;
            nodeDict[from] = parent;
        }
        
        if ( root == nil )
            root = parent;
        
        Node *child = nodeDict[to];
        if ( child == nil )
        {
            child = [parent addNewChildWithName:to];
            nodeDict[to] = child;
        }
        else
        {
            // see if this is a circular dependancy
            if ( ![child hasChildNodeWithName:parent.nodeNr] )
            {
                child.parent = parent;
                [parent addChildNode:child];
            }
            else
            {
                [parent.backRefs addObject:child];
            }
        }
    }
    
    return root;
}



// Drawing code
- (UIImage *) generateImageFromNode:(Node *)root
{
    [root layoutTree];
    CGSize treeSize = [root getSizeOfTree];
    
    
    UIGraphicsBeginImageContext(treeSize);
    
    // Now draw out image
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    [self drawLinesFromNode:root withContext:ctx];
    
    [self drawBackRefsLinesFromNode:root withContext:ctx];
    
    CGContextSetShadow(ctx, CGSizeMake(10.0f, 10.0f), 10.0f);
    [self drawChildNodesFromNode:root withContext:ctx];
    
    CGContextStrokePath(ctx);
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (void) drawLinesFromNode:(Node *)node withContext:(CGContextRef) ctx;
{
    CGPoint start = node.center;
    
    for ( Node *nv in node.children )
    {
        CGPoint to = nv.center;
        
        CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1.0);
        [self drawLine:ctx from:start to:to];
        
        [self drawLinesFromNode:nv withContext:ctx];
    }
    
    [self drawBackRefsLinesFromNode:node withContext:ctx];
    
}

- (void) drawBackRefsLinesFromNode:(Node *)node withContext:(CGContextRef) ctx;
{
    CGPoint start = node.center;
    CGContextSetRGBStrokeColor(ctx, 0, 0, 1, 1.0);
    for ( Node *nv in node.backRefs )
    {
        CGPoint to = nv.center;
        
        [self drawLine:ctx from:start to:to];
        
        [self drawBackRefsLinesFromNode:nv withContext:ctx];
    }
}


- (void) drawChildNodesFromNode:(Node*)node withContext:(CGContextRef)ctx
{
    int nodeIndex = [node.nodeNr intValue];
    if ( nodeIndex == -1 )
        return;
    ImageDetails *imageDetails = self.project[nodeIndex];
    UIImage *image = [imageDetails getThumbImage];
    
    [image drawInRect:node.frame];
    
    CGContextSetRGBStrokeColor(ctx, 0, 0, 1, 1.0);
    CGContextStrokeRect(ctx, node.frame);
    
    CGPoint p = (CGPoint){ node.frame.origin.x + 5, node.frame.origin.y + 5};
    [self drawString:node.nodeNr withFont:[UIFont systemFontOfSize:18] atPoint:p ];
    
    for ( Node *nv in node.children )
    {
        [self drawChildNodesFromNode:nv withContext:ctx];
    }
}

- (void) drawString: (NSString*) s withFont: (UIFont*) font atPoint:(CGPoint) point
{
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    
//    [s drawAtPoint:point withAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],
//                                            NSParagraphStyleAttributeName : style,
//                                            NSFontAttributeName : font}];
    
    
    NSDictionary *bgAttribs = @{NSFontAttributeName :  font,
                               NSStrokeWidthAttributeName : @(-1.0),
                               NSStrokeColorAttributeName : [UIColor blackColor]};
    NSDictionary *fgAttribs = @{NSFontAttributeName :  font,
                               NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    // draw bottom string in two passes
    [s drawAtPoint:point withAttributes:bgAttribs];
    [s drawAtPoint:point withAttributes:fgAttribs];

}


- (void) drawLine: (CGContextRef) context from: (CGPoint) from to: (CGPoint) to
{
    double slopy, cosy, siny;
    // Arrow size
    double length = 10.0;
    double width = 5.0;
    
    slopy = atan2((from.y - to.y), (from.x - to.x));
    cosy = cos(slopy);
    siny = sin(slopy);
    
    // make the line slightly shorter
    from.x -= 5*cosy;
    from.y -= 5*siny;
    to.x += (BLOCK_WIDTH+20)/2*cosy;
    to.y += (BLOCK_HEIGHT+20)/2*siny;
    
    //draw a line between the 2 endpoint
    CGContextMoveToPoint(context, from.x - length * cosy, from.y - length * siny );
    CGContextAddLineToPoint(context, to.x + length * cosy, to.y + length * siny);
    //paints a line along the current path
    CGContextStrokePath(context);
    
    
    /*/-------------similarly the the other end-------------/*/
    CGContextMoveToPoint(context, to.x, to.y);
    CGContextAddLineToPoint(context,
                            to.x +  (length * cosy - ( width / 2.0 * siny )),
                            to.y +  (length * siny + ( width / 2.0 * cosy )) );
    CGContextAddLineToPoint(context,
                            to.x +  (length * cosy + width / 2.0 * siny),
                            to.y -  (width / 2.0 * cosy - length * siny) );
    CGContextClosePath(context);
    CGContextStrokePath(context);
}


@end
