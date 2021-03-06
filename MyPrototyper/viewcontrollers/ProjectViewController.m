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
#import "ProjectStructureViewController.h"
#import "Project.h"
#import "ImageDetails.h"
#import "PhotoCell.h"
#import "PopoverView.h"


#import "AlbumSelectViewController.h"
#import "IASKAppSettingsViewController.h"


// Menu items
#define MENU_SET_START_IMAGE @"Set start image"
#define MENU_DELETE_IMAGES @"Delete images"
#define MENU_REORDER_FILES @"Re-order files"
#define MENU_EXPORT_PROJECT @"Export project"
#define MENU_SETTINGS @"Settings"
#define MENU_SHOW_PROJECT_STRUCTURE @"Show project structure"

#define MENU_NEW_IMAGE @"New blank image"
#define MENU_TAKE_CAMERA @"Take from camera"
#define MENU_ADD_LIBRARY @"Add from library"



@interface ProjectViewController () <DrawViewControllerDelegate, AlbumSelectViewControllerDelegate, IASKSettingsDelegate, PopoverViewDelegate, UIDocumentInteractionControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
{
    UIDocumentInteractionController *docController;
    
    Project *project;
    ImageDetails *selectedImageDetails;
    
    bool editMode;
    bool reordering;
    UIBarButtonItem *actionBtn;
    UIBarButtonItem *doneBtn;
    UIBarButtonItem *doneReorderBtn;
    UIBarButtonItem *deleteBtn;
    UIBarButtonItem *backBtn;
    
    PopoverView *popoverView;
    
    bool settingStartImage;
    
    UITextField *txtTitleBar;
    
    UIImageView *zoomImageView;
    CGRect zoomOrigFrame;
    
    // Used for reordering cells
    NSIndexPath *selectedIndexPath;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectStartImageDisplayViewBottom;
@property (weak, nonatomic) IBOutlet UIView *selectStartImageDisplayView;
@property (weak, nonatomic) IBOutlet UILabel *infoTitleLabel;

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
    doneReorderBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(reorderPressed:)];
    deleteBtn = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deletePressed:)];
    
    self.navigationItem.rightBarButtonItem = actionBtn;
    
    [self.collectionView reloadData];
    
    self.selectStartImageDisplayViewBottom.constant -= self.selectStartImageDisplayView.bounds.size.height;
    
    UITapGestureRecognizer* tapRecon = [[UITapGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(navigationBarDoubleTap:)];
    tapRecon.numberOfTapsRequired = 2;
    [self.navigationController.navigationBar addGestureRecognizer:tapRecon];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(processLongTouch:)];
    [longPress setMinimumPressDuration:0.25];
    [self.collectionView addGestureRecognizer:longPress];
}

- (void)navigationBarDoubleTap:(UIGestureRecognizer*)recognizer {
    txtTitleBar = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, 80, 22)];
    txtTitleBar.text = self.title;
    txtTitleBar.font = [UIFont boldSystemFontOfSize:18];
    txtTitleBar.textColor = [UIColor whiteColor];
    txtTitleBar.textAlignment = NSTextAlignmentCenter;
    txtTitleBar.delegate = self;
    txtTitleBar.returnKeyType = UIReturnKeyDone;
    self.navigationItem.titleView = txtTitleBar;
    [txtTitleBar becomeFirstResponder];
    [txtTitleBar setSelectedTextRange:[txtTitleBar textRangeFromPosition:txtTitleBar.beginningOfDocument toPosition:txtTitleBar.endOfDocument]];
}

- (void) viewWillDisappear:(BOOL)animated
{
    if ( popoverView != nil )
    {
        [popoverView dismiss];
    }
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
    
    if ( [segue.identifier isEqualToString:@"ShowAddAlbum"] )
    {
        AlbumSelectViewController *vc = segue.destinationViewController;
        vc.delegate = self;
    }

    if ( [segue.identifier isEqualToString:@"ShowProjectStructure"] )
    {
        ProjectStructureViewController *vc = segue.destinationViewController;
        vc.project = project;
    }    
}

- (IBAction)unwindFromViewController:(UIStoryboardSegue *)segue
{
    [self saveProject];
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
    
    [cell setImage:[imageDetails getThumbImage] withBadgeText:[NSString stringWithFormat:@"%d", indexPath.row]];
    cell.backgroundColor = [UIColor clearColor];
    
    if ( [project.startImage isEqualToString:imageDetails.imageName] )
    {
        cell.layer.borderColor = [UIColor colorWithRed:0.224 green:0.576 blue:0.996 alpha:1.000].CGColor;
        cell.layer.borderWidth = 2;
    }
    else
    {
        cell.layer.borderColor = [UIColor lightGrayColor].CGColor;
        cell.layer.borderWidth = 2;
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


- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( settingStartImage )
    {
        ImageDetails *imageDetails = project[indexPath.row];
        project.startImage = imageDetails.imageName;
        
        [self saveProject];
        
        self.selectStartImageDisplayViewBottom.constant -= self.selectStartImageDisplayView.bounds.size.height;
        [UIView animateWithDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        }];
        
        [self.collectionView reloadData];
        settingStartImage = NO;
    }
    else if ( reordering )
    {
        if ( selectedIndexPath == nil )
        {
            PhotoCell *cell = (PhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.backgroundColor = [UIColor yellowColor];
            selectedIndexPath = indexPath;
            self.infoTitleLabel.text = @"Select the image position to move before";
        }
        else
        {
            // Move image at previous selected index path to after the selected on
            [project moveImageAtIndex:selectedIndexPath.row toAfter:indexPath.row];
            [self.collectionView reloadData];
            selectedIndexPath = nil;
            self.infoTitleLabel.text = @"Select the image to move";
        }
    }
    else if ( !editMode )
    {
        selectedImageDetails = project[indexPath.row];
        
        // Do something with the image
        [self performSegueWithIdentifier:@"EditImage" sender:self];
    }
    else
    {
        PhotoCell *cell = (PhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.highlight = cell.selected;
        [cell setNeedsDisplay];
    }
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editMode )
    {
        PhotoCell *cell = (PhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.highlight = cell.selected;
        [cell setNeedsDisplay];
    }
}

#pragma mark - Zooming a selected cell

- (void) processLongTouch:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [sender locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        
        if (indexPath)
        {
            PhotoCell *cell = (PhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            zoomOrigFrame = CGRectInset( cell.frame, 5, 5 );
            zoomOrigFrame.origin.x -= self.collectionView.contentOffset.x;
            zoomOrigFrame.origin.y -= self.collectionView.contentOffset.y;
            
            ImageDetails *imageDetails = project[indexPath.row];

            zoomImageView = [[UIImageView alloc] initWithImage:[imageDetails getImage]];
            zoomImageView.layer.borderWidth = 1;
            zoomImageView.layer.borderColor = [UIColor blackColor].CGColor;
            
            zoomImageView.frame = zoomOrigFrame;
            [self.view addSubview:zoomImageView];
            [UIView animateWithDuration:0.25 animations:^{
                CGRect f = self.view.bounds;
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
            [self.collectionView reloadData];
        }];
    }
}


#pragma mark - Actions

-( IBAction) actionPressed:(id)sender
{
    NSArray *items = @[MENU_SET_START_IMAGE, MENU_DELETE_IMAGES, MENU_REORDER_FILES, MENU_EXPORT_PROJECT, MENU_SETTINGS, MENU_SHOW_PROJECT_STRUCTURE];
    popoverView = [PopoverView showPopoverAtPoint:CGPointMake( self.view.frame.size.width - 20, 0) inView:self.view withTitle:@"Action" withStringArray:items delegate:self];
}

- (IBAction)addImagePressed:(id)sender
{
    NSArray *items = @[MENU_NEW_IMAGE, MENU_TAKE_CAMERA, MENU_ADD_LIBRARY];
    popoverView = [PopoverView showPopoverAtPoint:CGPointMake( 20, self.view.frame.size.height - 44) inView:self.view withStringArray:items delegate:self];
    
}



#pragma mark - PopoverView delegate

- (void)popoverView:(PopoverView *)thePopoverView didSelectItemAtIndex:(NSInteger)index itemText:(NSString *)text
{
    [popoverView dismiss];
    popoverView = nil;

    // Items from action menu button
    if ( [text isEqualToString:MENU_SET_START_IMAGE] )
    {
        settingStartImage = YES;
        self.infoTitleLabel.text = @"Select the starting image";
        self.selectStartImageDisplayViewBottom.constant += self.selectStartImageDisplayView.bounds.size.height;
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    if ( [text isEqualToString:MENU_DELETE_IMAGES] )
    {
        [self editPressed:nil];
    }
    
    if ( [text isEqualToString:MENU_REORDER_FILES] )
    {
        [self reorderPressed:nil];
    }
    
    
    if ( [text isEqualToString:MENU_EXPORT_PROJECT] )
    {
        [self exportProject];
    }

    
    if ( [text isEqualToString:MENU_SETTINGS] )
    {
        IASKAppSettingsViewController *appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
        appSettingsViewController.delegate = self;
        
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            appSettingsViewController.showDoneButton = YES;
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:appSettingsViewController];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            
            [self presentViewController:nc animated:YES completion:^{ }];
        }
        else
        {
            appSettingsViewController.showDoneButton = NO;
            [self.navigationController pushViewController:appSettingsViewController animated:YES];
        }
    }
    
    if ( [text isEqualToString:MENU_SHOW_PROJECT_STRUCTURE] )
    {
        [self performSegueWithIdentifier:@"ShowProjectStructure" sender:self];
        
    }
    
    
    // Items from add new image button
    if ( [text isEqualToString:MENU_NEW_IMAGE] )
    {
        [self performSegueWithIdentifier:@"ShowDraw" sender:self];
    }
    if ( [text isEqualToString:MENU_TAKE_CAMERA] )
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
    if ( [text isEqualToString:MENU_ADD_LIBRARY] )
    {
        if (([UIImagePickerController isSourceTypeAvailable:
              UIImagePickerControllerSourceTypePhotoLibrary] == NO))
            return;
        
        [self performSegueWithIdentifier:@"ShowAddAlbum" sender:self];
    }
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

- (void) reorderPressed:(id)sender
{
    reordering = !reordering;
    if ( reordering )
    {
        self.navigationItem.rightBarButtonItem = doneReorderBtn;
        self.infoTitleLabel.text = @"Select the image to move";
        self.selectStartImageDisplayViewBottom.constant += self.selectStartImageDisplayView.bounds.size.height;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = actionBtn;
        
        self.selectStartImageDisplayViewBottom.constant -= self.selectStartImageDisplayView.bounds.size.height;
        [self saveProject];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
    
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
        
        CGFloat imageQuality = [[[NSUserDefaults standardUserDefaults] objectForKey:PREF_IMAGE_QUALITY] floatValue];
        bool rc = [UIImageJPEGRepresentation(i, imageQuality) writeToFile:imageDetails.imagePath atomically:YES];
        if ( !rc )
        {
            NSLog( @"Failed to convert %@", imageDetails.imageName );
        }
    }
    
    [self saveProject];
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

#pragma mark - DrawViewControllerDelegateMethods
- (void) drawImageChanged:(UIImage *)image
{
    [project addImageToProject:image];
    [self.collectionView reloadData];
}

#pragma mark - ELCImagePickerController delegates
- (void) imagesSelected:(NSArray *)info
{
    [self.navigationController popViewControllerAnimated:YES];
    
	for (NSDictionary *dict in info) {
        
        UIImage *image = [dict objectForKey:UIImagePickerControllerOriginalImage];
        
        image = [self scaleAndRotateImage:image];
        [project addImageToProject:image];
	}
    
    [self.collectionView reloadData];
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

#pragma mark - InAppSettingsKit Delegate
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextField delegate methods (for editing titlebar)
- (void) textFieldDidEndEditing:(UITextField *)textField
{
    // Rename project if name not the same
    if ( textField == txtTitleBar )
    {
        NSString *text = textField.text;
        if ( text.length > 0 && ![text isEqualToString:project.projectName] )
        {
            NSError *err = nil;
            [project renameProject:text error:&err];
            if ( err == nil )
            {
                self.title = project.projectName;
            }
            else
            {
                // Display alert
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Problem" message:err.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
            }
        }
        self.navigationItem.titleView = nil;
        txtTitleBar = nil;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ( textField == txtTitleBar )
    {
        [textField resignFirstResponder];
        return NO;
    }
    
    return YES;
}


- (void) saveProject
{
    NSError *err = nil;
    [project save:&err];
    if ( err != nil )
        NSLog( @"Error saving project - %@", err.localizedDescription );
}
@end
