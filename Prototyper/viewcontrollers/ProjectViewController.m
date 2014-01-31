//
//  ProjectViewController.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ProjectViewController.h"
#import "ImageEditViewController.h"
#import "PlaybackViewController.h"
#import "DrawViewController.h"
#import "Project.h"
#import "ImageDetails.h"
#import "PhotoCell.h"
#import "PSPDFActionSheet.h"

#import <ELCImagePickerController/ELCImagePickerController.h>

@interface ProjectViewController () <DrawViewControllerDelegate, ELCImagePickerControllerDelegate, UIDocumentInteractionControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIDocumentInteractionController *docController;

    Project *project;
    ImageDetails *selectedImageDetails;
    
    bool editMode;
    UIBarButtonItem *actionBtn;
    UIBarButtonItem *doneBtn;
    UIBarButtonItem *deleteBtn;
    UIBarButtonItem *backBtn;
    
    PSPDFActionSheet *popupSheet;
    
    bool settingStartImage;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectStartImageDisplayViewBottom;
@property (weak, nonatomic) IBOutlet UIView *selectStartImageDisplayView;

@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property(nonatomic, strong) NSArray *assets;
@end

@implementation ProjectViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.projectName;
    project = [[Project alloc] initWithProjectName:self.projectName];
    
    actionBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionPressed:)];
    doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editPressed:)];
    deleteBtn = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deletePressed:)];
    
    self.navigationItem.rightBarButtonItem = actionBtn;

    [self.collectionView reloadData];
    
    self.selectStartImageDisplayViewBottom.constant -= self.selectStartImageDisplayView.bounds.size.height;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"EditImage"] )
    {
        ImageEditViewController *vc = segue.destinationViewController;
        vc.project = project;
        vc.imageDetails = selectedImageDetails;
        selectedImageDetails = nil;
    }
    if ( [segue.identifier isEqualToString:@"showPlaybackVC"] )
    {
        PlaybackViewController *vc = segue.destinationViewController;
        vc.project = project;
        
    }
    if ( [segue.identifier isEqualToString:@"ShowDraw"] )
    {
        DrawViewController *vc = segue.destinationViewController;
        vc.delegate = self;
    }
}

- (IBAction)unwindFromViewController:(UIStoryboardSegue *)segue
{
    [project save];
    
    // Unselect all items
    for ( NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems] )
         [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    [self.collectionView reloadData];
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
    
    UIImage *i = [imageDetails getImage];
    cell.image = i;
    cell.backgroundColor = [UIColor clearColor];
    
    if ( [project.startImage isEqualToString:imageDetails.imageName] )
        cell.backgroundColor = [UIColor blueColor];
    
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


- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( settingStartImage )
    {
        ImageDetails *imageDetails = project[indexPath.row];
        project.startImage = imageDetails.imageName;
        [project save];
        
        self.selectStartImageDisplayViewBottom.constant -= self.selectStartImageDisplayView.bounds.size.height;
        [UIView animateWithDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        }];

        [self.collectionView reloadData];
        settingStartImage = NO;
    }
    else if ( !editMode )
    {
        selectedImageDetails = project[indexPath.row];
        
        // Do something with the image
        [self performSegueWithIdentifier:@"EditImage" sender:self];
    }
}


#pragma mark - Actions

- (void) actionPressed:(id)sender
{
    if ( popupSheet != nil )
    {
        [popupSheet dismissWithClickedButtonIndex:0 animated:YES];
        popupSheet = nil;
        return;
    }
    
    // Display Action sheet in popever
    popupSheet = [[PSPDFActionSheet alloc] initWithTitle:@"Action"];
    
    __block __typeof__(self) blockSelf = self;
    
    
    [popupSheet addButtonWithTitle:@"Set start image" block:^{
        blockSelf->popupSheet = nil;
        blockSelf->settingStartImage = YES;
        blockSelf.selectStartImageDisplayViewBottom.constant += blockSelf.selectStartImageDisplayView.bounds.size.height;

        [UIView animateWithDuration:0.25 animations:^{
            [blockSelf.view layoutIfNeeded];
        }];

    }];
    
    
    [popupSheet addButtonWithTitle:@"Delete images" block:^{
        
        blockSelf->popupSheet = nil;
        [blockSelf editPressed:sender];
    }];
    
    [popupSheet addButtonWithTitle:@"Export project" block:^{
        
        blockSelf->popupSheet = nil;
        [blockSelf exportProject];
    }];
    
    [popupSheet addButtonWithTitle:@"Compress images" block:^{
        
        blockSelf->popupSheet = nil;
        [blockSelf compressImages];
    }];
    
    [popupSheet setCancelButtonWithTitle:@"Cancel" block:^{
        blockSelf->popupSheet = nil;
    }];
    
    [popupSheet showWithSender:sender fallbackView:self.view animated:YES];

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
        self.navigationItem.rightBarButtonItem = actionBtn;
        self.collectionView.allowsMultipleSelection = NO;
        
        [self.collectionView reloadData];
    }
}

- (void) exportProject
{
    NSString *exportPath = [project exportFile];
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:exportPath];
    docController = [UIDocumentInteractionController interactionControllerWithURL:url];
    docController.URL = url;
    docController.delegate = self;
    bool rc = [docController presentOptionsMenuFromBarButtonItem:actionBtn animated:YES];
    
    NSLog( @"rc = %d", rc );

}


- (void) compressImages
{
    for ( int i = 0 ; i < project.count ; ++i )
    {
        ImageDetails *imageDetails = project[i];
        
        UIImage *i = [imageDetails getImage];
        NSLog( @"Converting %@", imageDetails.imageName );
        
        imageDetails.imagePath = [imageDetails.imagePath stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"];

        bool rc = [UIImageJPEGRepresentation(i, 0.5) writeToFile:imageDetails.imagePath atomically:YES];
        if ( !rc )
        {
            NSLog( @"Failed to convert %@", imageDetails.imageName );
        }
    }
    
    [project save];
    
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
    
    
    ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] init];
    elcPicker.imagePickerDelegate = self;
    
    [self presentViewController:elcPicker animated:YES completion:nil];
}

#pragma mark - DrawViewControllerDelegateMethods
- (void) drawImageChanged:(UIImage *)image
{
    [project addImageToProject:image];
    [self.collectionView reloadData];
}

#pragma mark - ELCImagePickerController delegates
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
		
	for (NSDictionary *dict in info) {
        
        UIImage *image = [dict objectForKey:UIImagePickerControllerOriginalImage];
        
        image = [self scaleAndRotateImage:image];
        [project addImageToProject:image];
	}
    
    [self.collectionView reloadData];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark - UIDocumentInteractionControllerDelegate methods

- (void) documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    NSURL *url = controller.URL;
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtURL:url error:&error];
    if ( error )
        NSLog( @"Error removing %@ - %@", url, error.localizedDescription );
}

@end
