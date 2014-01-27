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

}

- (BOOL)prefersStatusBarHidden
{
    return NO;
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
    
        
    if ( [self.linkedId isEqualToString:imageDetails.imageName] )
    {
        selectedIndex = indexPath.row;
        self.navigationItem.rightBarButtonItem = doneBtn;

        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        cell.selected = YES;
    }
    
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
        selectedIndex = -1;
        self.navigationItem.rightBarButtonItem = nil;
        return NO;
    }
    
    return YES;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( selectedIndex == indexPath.row )
        [self donePressed:nil];
    
    selectedIndex = indexPath.row;
    self.navigationItem.rightBarButtonItem = doneBtn;
}


- (void) donePressed:(id)sender
{
    ImageDetails *details = self.project[selectedIndex];
    
    [self.delegate LIVC_didSelectImage:details.imageName];
    [self.navigationController popViewControllerAnimated:YES];
}

@end