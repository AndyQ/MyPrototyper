//
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ViewController.h"
#import "ImageEditViewController.h"
#import "PlaybackViewController.h"
#import "Project.h"
#import "ImageDetails.h"
#import "PhotoCell.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    Project *project;
    ImageDetails *selectedImageDetails;
    
    bool editMode;
    UIBarButtonItem *editBtn;
    UIBarButtonItem *doneBtn;
    UIBarButtonItem *deleteBtn;
    UIBarButtonItem *backBtn;
}

@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property(nonatomic, strong) NSArray *assets;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.projectName = @"Default";
    project = [Project setupProject:self.projectName];
    
    editBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editPressed:)];
    doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editPressed:)];
    deleteBtn = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deletePressed:)];
    
    self.navigationItem.rightBarButtonItem = editBtn;

    [self.collectionView reloadData];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"EditImage"] )
    {
        UINavigationController *nc = segue.destinationViewController;
        ImageEditViewController *vc = (ImageEditViewController *)nc.topViewController;
        vc.project = project;
        vc.imageDetails = selectedImageDetails;
        selectedImageDetails = nil;
    }
    if ( [segue.identifier isEqualToString:@"showPlaybackVC"] )
    {
        PlaybackViewController *vc = segue.destinationViewController;
        vc.project = project;

    }
}

- (IBAction)unwindFromViewController:(UIStoryboardSegue *)segue
{
    [project save];
    
    // Unselect all items
    for ( NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems] )
         [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
}



#pragma mark - collection view data source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return project.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    
    ImageDetails *imageDetails = project[indexPath.row];
    
    cell.image = [UIImage imageWithContentsOfFile:imageDetails.imagePath];
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void) editPressed:(id)sender
{
    editMode = !editMode;
    if ( editMode )
    {
        self.navigationItem.leftBarButtonItem = doneBtn;
        self.navigationItem.rightBarButtonItem = deleteBtn;
        
        self.collectionView.allowsMultipleSelection = YES;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = editBtn;
        self.collectionView.allowsMultipleSelection = NO;
    }
}

- (void) deletePressed:(id)sender
{
    // Remove selected cells
    NSArray *selectedCells = [self.collectionView indexPathsForSelectedItems];
    
    // Remove images from project
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    for ( NSIndexPath *indexPath in selectedCells )
    {
        [itemsToDelete addObject:project[indexPath.row]];
    }

    for ( ImageDetails *item in itemsToDelete )
        [project removeItem:item];
    [self.collectionView deleteItemsAtIndexPaths:selectedCells];
    
    [self editPressed:nil];
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


- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( !editMode )
    {
        selectedImageDetails = project[indexPath.row];
        
        // Do something with the image
        [self performSegueWithIdentifier:@"EditImage" sender:self];
    }
}


#pragma mark - Actions

- (IBAction)takePhotoButtonTapped:(id)sender
{
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO))
    {
        UIImage *image = [UIImage imageNamed:@"Dummy"];
        [project addImageToProject:image];
        [self.collectionView reloadData];
        return;
    }
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    [self presentViewController:mediaUI animated:YES completion:nil];
}

- (IBAction)albumsButtonTapped:(id)sender
{
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypePhotoLibrary] == NO))
        return;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    [self presentViewController:mediaUI animated:YES completion:nil];
    
}

#pragma mark - image picker delegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = (UIImage *) info[UIImagePickerControllerOriginalImage];
    image = [self scaleAndRotateImage:image];
    [self dismissViewControllerAnimated:YES completion:^{
        
        [project addImageToProject:image];
        [self.collectionView reloadData];
    }];
}


- (UIImage *) scaleAndRotateImage: (UIImage *)image
{
    int kMaxResolution = 1024; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }

    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}
@end
