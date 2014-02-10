//
//  LinkImageViewController.m
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "LinkImageViewController.h"
#import "ImageDetails.h"
#import "PhotoCell.h"


/**
 * This is basically just a Collection view allowing the user to select an image to link to
 * double tapping the image will select it as will selecting the image then selecting the done button
 */


@interface LinkImageViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSInteger selectedIndex;
    
    UIBarButtonItem *doneBtn;
    UIImageView *zoomImageView;
    CGRect zoomOrigFrame;
}

@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation LinkImageViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    selectedIndex = -1;
    
    doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];

    [self.collectionView reloadData];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(processLongTouch:)];
    [longPress setMinimumPressDuration:0.25];
    [self.collectionView addGestureRecognizer:longPress];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}


- (void) processLongTouch:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [sender locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];

        if (indexPath)
        {
            ImageDetails *imageDetails = self.project[indexPath.row];
            if ( [self.currentImageId isEqualToString:imageDetails.imageName] )
                return;
        
            PhotoCell *cell = (PhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            zoomOrigFrame = CGRectInset( cell.frame, 5, 5 );
            zoomOrigFrame.origin.x -= self.collectionView.contentOffset.x;
            zoomOrigFrame.origin.y -= self.collectionView.contentOffset.y;
            
            zoomImageView = [[UIImageView alloc] initWithImage:cell.image];
            zoomImageView.layer.borderWidth = 1;
            zoomImageView.layer.borderColor = [UIColor blackColor].CGColor;
            
            zoomImageView.frame = zoomOrigFrame;
            [self.view addSubview:zoomImageView];
            [UIView animateWithDuration:0.5 animations:^{
                CGRect f = self.view.bounds;
                zoomImageView.frame = f;
            }];
        }
    }
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [UIView animateWithDuration:0.5 animations:^{
            zoomImageView.frame = zoomOrigFrame;
        } completion:^(BOOL finished) {
            [zoomImageView removeFromSuperview];
            zoomImageView = nil;
            [self.collectionView reloadData];
        }];
    }
}


#pragma mark - collection view data source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.project.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    
    ImageDetails *imageDetails = self.project[indexPath.row];
    cell.image = [imageDetails getImage];
    
    if ( [self.currentImageId isEqualToString:imageDetails.imageName] )
        cell.contentView.alpha = 0.3;
    else
        cell.contentView.alpha = 1;
    
        
    if ( (selectedIndex == -1 && [self.linkedId isEqualToString:imageDetails.imageName]) || selectedIndex == indexPath.row )
    {
        selectedIndex = indexPath.row;
        self.navigationItem.rightBarButtonItem = doneBtn;

        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        cell.highlight = YES;
    }
    else
        cell.highlight = NO;
    
    return cell;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 4;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

#pragma mark - collection view delegate

- (BOOL) collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageDetails *imageDetails = self.project[indexPath.row];
    if ( [self.currentImageId isEqualToString:imageDetails.imageName] )
    {
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
        PhotoCell *cell = (PhotoCell *)[collectionView cellForItemAtIndexPath:oldIndexPath];
        cell.highlight = YES;

        self.navigationItem.rightBarButtonItem = nil;
        return NO;
    }
    
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( selectedIndex == indexPath.row )
        [self donePressed:nil];
    
    if ( selectedIndex != -1 )
    {
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
        PhotoCell *cell = (PhotoCell *)[collectionView cellForItemAtIndexPath:oldIndexPath];
        cell.highlight = NO;
        [cell setNeedsDisplay];
    }
    
    selectedIndex = indexPath.row;
    PhotoCell *cell = (PhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.highlight = YES;
    [cell setNeedsDisplay];
    
    self.navigationItem.rightBarButtonItem = doneBtn;
}


- (void) donePressed:(id)sender
{
    ImageDetails *details = self.project[selectedIndex];
    
    [self.delegate LIVC_didSelectImage:details.imageName];
    [self.navigationController popViewControllerAnimated:YES];
}

@end