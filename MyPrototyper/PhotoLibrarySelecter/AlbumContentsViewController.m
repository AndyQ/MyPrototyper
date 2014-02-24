/*
     File: AlbumContentsViewController.m
 Abstract: View controller to manaage displaying the contents of an album.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "AlbumContentsViewController.h"

@implementation AlbumContentsViewController
{
    UIImageView *zoomImageView;
    CGRect zoomOrigFrame;

    NSMutableArray *selectedItems;
}
#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.collectionView.allowsMultipleSelection = YES;
    selectedItems = [NSMutableArray array];
    
    self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    if (!self.assets) {
        _assets = [[NSMutableArray alloc] init];
    } else {
        [self.assets removeAllObjects];
    }
    
    ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if (result) {
            [self.assets addObject:result];
        }
    };

    ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
    [self.assetsGroup setAssetsFilter:onlyPhotosFilter];
    [self.assetsGroup enumerateAssetsUsingBlock:assetsEnumerationBlock];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(processLongTouch:)];
    longPress.cancelsTouchesInView = NO;
    [longPress setMinimumPressDuration:0.25];
    [self.collectionView addGestureRecognizer:longPress];

}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.collectionView reloadData];
}


#pragma mark - UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    
    return self.assets.count;
}

#define kImageViewTag 1 // the image view inside the collection view cell prototype is tagged with "1"
#define kOverlayImageViewTag 2 // the image view inside the collection view cell prototype is tagged with "1"

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"photoCell";
    
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // load the asset for this cell
    ALAsset *asset = self.assets[indexPath.row];
    CGImageRef thumbnailImageRef = [asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];

    // apply the image to the cell
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:kImageViewTag];
    imageView.image = thumbnail;

    bool selected = [selectedItems containsObject:indexPath];
    if ( selected )
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:NO];
    imageView = (UIImageView *)[cell viewWithTag:kOverlayImageViewTag];
    imageView.hidden = !selected;
    
    return cell;
}

- (void) processLongTouch:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [sender locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        
        if (indexPath)
        {
            ALAsset *asset = self.assets[indexPath.row];
            ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
            
            UIImage *image = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage]
                                                           scale:[assetRepresentation scale]
                                                     orientation:UIImageOrientationUp];

            
            UICollectionViewCell *cell = (UICollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            zoomOrigFrame = CGRectInset( cell.frame, 5, 5 );
            zoomOrigFrame.origin.x -= self.collectionView.contentOffset.x;
            zoomOrigFrame.origin.y -= self.collectionView.contentOffset.y;
            
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
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [UIView animateWithDuration:0.25 animations:^{
            zoomImageView.frame = zoomOrigFrame;
        } completion:^(BOOL finished) {
            [zoomImageView removeFromSuperview];
            zoomImageView = nil;
        }];
    }
}

- (BOOL) collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( zoomImageView != nil )
    {
        return NO;
    }
    
    return YES;
}

- (BOOL) collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( zoomImageView != nil )
    {
        return NO;
    }
    
    return YES;
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [selectedItems addObject:indexPath];
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    
    
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [selectedItems removeObject:indexPath];
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

#pragma mark - Done pressed
- (IBAction) donePressed:(id)sender
{
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];

    for ( NSIndexPath *indexPath in selectedItems )
    {
        ALAsset *asset = self.assets[indexPath.row];
		id obj = [asset valueForProperty:ALAssetPropertyType];
		if (!obj) {
			continue;
		}

        ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
        
        UIImage *image = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage]
                                             scale:[assetRepresentation scale]
                                       orientation:UIImageOrientationUp];
        
		NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
        workingDictionary[UIImagePickerControllerMediaType] = obj;
        workingDictionary[UIImagePickerControllerOriginalImage] = image;
        workingDictionary[UIImagePickerControllerReferenceURL] = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]];

        [returnArray addObject:workingDictionary];
    }
    
    [self.delegate imagesSelected:returnArray];
}
@end

