//
//  MainViewController.m
//  Prototyper
//
//  Created by Andy Qua on 12/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "MainViewController.h"
#import "ProjectViewController.h"
#import "Project.h"
#import "ItemCell.h"
#import "PopoverView.h"

#import "Constants.h"

#import "IASKAppSettingsViewController.h"

@interface MainViewController () <IASKSettingsDelegate, PopoverViewDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
{
    PopoverView *popoverView;

    NSMutableArray *projects;
    NSString *selectedProjectName;
    
    UIBarButtonItem *addButton;
    UIBarButtonItem *actionButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *deleteButton;
    
    bool editMode;
}

@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];\
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProjectPressed:)];
    actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionPressed:)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(deleteProjectsPressed:)];
    deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deletePressed:)];

    self.navigationItem.leftBarButtonItem = addButton;
    self.navigationItem.rightBarButtonItem = actionButton;
}

- (void) viewWillAppear:(BOOL)animated
{
    // Register for import notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadProjects) name:NOTIF_IMPORTED object:nil];

    [self loadProjects];
    [self.collectionView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



- (void) deleteProjectsPressed:(id)sender
{
    editMode = !editMode;
    if ( editMode )
    {
        self.navigationItem.leftBarButtonItem = doneButton;
        self.navigationItem.rightBarButtonItem = deleteButton;
        
        self.collectionView.allowsMultipleSelection = YES;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = addButton;
        self.navigationItem.rightBarButtonItem = actionButton;
        self.collectionView.allowsMultipleSelection = NO;
        
        [self.collectionView reloadData];
    }
}


- (IBAction) addProjectPressed:(id)sender
{
    // prompt for name
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Enter project name" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    [av show];
}

-( IBAction) actionPressed:(id)sender
{
    NSArray *items = @[@"Delete projects", @"Settings", @"Add demo project"];
    popoverView = [PopoverView showPopoverAtPoint:CGPointMake( self.view.frame.size.width - 20, 0) inView:self.view withTitle:@"Action" withStringArray:items delegate:self];
}

#pragma mark - PopoverView delegate

- (void)popoverView:(PopoverView *)thePopoverView didSelectItemAtIndex:(NSInteger)index itemText:(NSString *)text
{
    if ( [text isEqualToString:@"Delete projects"] )
    {
        [self deleteProjectsPressed:nil];
    }
    else if ( [text isEqualToString:@"Settings"] )
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
    else if ( [text isEqualToString:@"Add demo project"] )
    {
        // Copy over demo file into place
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"demo" withExtension:@"zip"];
        [Project importProjectArchiveFromURL:url error:nil];
        
        [self loadProjects];
        [self.collectionView reloadData];
    }

    [popoverView dismiss];
    popoverView = nil;
    
}

- (void)popoverViewDidDismiss:(PopoverView *)thePopoverView;
{
    popoverView = nil;
}


- (void) donePressed:(id)sender
{
    editMode = NO;
    [self.collectionView reloadData];

    self.navigationItem.leftBarButtonItem = addButton;
    self.navigationItem.rightBarButtonItem = actionButton;
}

#pragma mark - UIAlertViewDelegate methods
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    NSString *inputText = [[alertView textFieldAtIndex:0] text];
    if ( [projects containsObject:inputText] || inputText.length == 0 )
        return NO;
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 1 )
    {
        NSString *name = [alertView textFieldAtIndex:0].text;
        
        Project *p = [[Project alloc] init];
        p.projectName = name;
        [projects addObject:p];
        [self.collectionView reloadData];
    }
}
#pragma mark - Load projects
- (void) loadProjects
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    projects = [NSMutableArray array];
    NSArray *files = [fm contentsOfDirectoryAtPath:[Project getDocsDir] error:nil];
    for ( NSString *file in files )
    {
        NSString *path = [[Project getDocsDir] stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        if (![file hasPrefix:@"."] && [fm fileExistsAtPath:path isDirectory:&isDir] && isDir)
        {
//            ProjectType projectType = [Project getProjectTypeForProject:file];
            Project *p = [[Project alloc] init];
            p.projectName = file;
//            p.projectType = projectType;
            [projects addObject:p];
        }
    }
    
    [self.collectionView reloadData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"ShowProject"] )
    {
        ProjectViewController *vc = segue.destinationViewController;
        vc.projectName = selectedProjectName;
    }
}


#pragma mark - collection view data source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return projects.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ItemCell *cell = (ItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"ItemCell" forIndexPath:indexPath];
    
    Project *project = projects[indexPath.row];
    cell.label.text = project.projectName;
    cell.backgroundColor = [UIColor clearColor];

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
    if ( !editMode )
    {
        Project *project = projects[indexPath.row];
        selectedProjectName = project.projectName;
        [self performSegueWithIdentifier:@"ShowProject" sender:self];
    }
    else
    {
        ItemCell *cell = (ItemCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.highlight = cell.selected;
        [cell setNeedsDisplay];
    }
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editMode )
    {
        ItemCell *cell = (ItemCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.highlight = cell.selected;
        [cell setNeedsDisplay];
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
        [itemsToDelete addObject:projects[indexPath.row]];
    }
    
    for ( Project *project in itemsToDelete )
    {
        [Project deleteProjectWithName:project.projectName];
        [projects removeObject:project];

    }
    [self.collectionView deleteItemsAtIndexPaths:selectedCells];
    
    [self deleteProjectsPressed:nil];
}


#pragma mark - InAppSettingsKit Delegate
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
