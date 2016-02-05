//
//  MainViewController.swift
//  Amazing Mask
//
//  Created by 刘洋 on 16/1/31.
//  Copyright © 2016年 Louie. All rights reserved.
//

import UIKit


class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate
{
    
    let MasksDefault: [String] = [
        "Sponge", "Starfish",
        "Vendetta",
        "Wolverine", "Hulk",
        "Hulk2", "Spider"
    ]
    
    let ocWrapper = OpenCVWrapper.init();
    
    @IBOutlet var centerImage: UIImageView!
    @IBOutlet var bottomStackView: UIStackView!

    /*********************** New Button begin ***********************/
    @IBOutlet var newImage: UIButton!
    @IBAction func onNew(sender: UIButton)
    {
        func showCamera()
        {
            let cameraPicker = UIImagePickerController()
            cameraPicker.delegate = self
            cameraPicker.sourceType = .Camera
            
            presentViewController(cameraPicker, animated: true, completion: nil)
        }
        func showAlbum()
        {
            let albumPicker = UIImagePickerController()
            albumPicker.delegate = self
            albumPicker.sourceType = .PhotoLibrary
            
            presentViewController(albumPicker, animated: true, completion: nil)
        }
        
        let actionSheet = UIAlertController(title: "New Image", message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { _ in
            showCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Album", style: .Default, handler: { _ in
            showAlbum()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: AnyObject])
    {
        dismissViewControllerAnimated(true, completion: nil)
        
        func fixOrientation(img:UIImage) -> UIImage {
            
            if (img.imageOrientation == UIImageOrientation.Up) {
                return img;
            }
            
            UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
            let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
            img.drawInRect(rect)
            
            let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext();
            return normalizedImage;
            
        }
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            centerImage.image = fixOrientation(image)
            centerImage.alpha = 1
            if (!roiButtons.isEmpty)
            {
                roiButtons[currentActiveButtonIndex].layer.borderWidth = 0
            }
            isProcessed = false
            changeStatus("Image Changed")
            isProcessedRoi.removeAll()
        }
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    /*********************** New Button end ***********************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cascadePath = NSHomeDirectory() + "/Documents/cascade.xml";
        if !NSFileManager.defaultManager().fileExistsAtPath(cascadePath)
        {
            let bundlecascadePath: String? = NSBundle.mainBundle().pathForResource("haarcascade_frontalface_alt", ofType: ".xml")
            try! NSFileManager.defaultManager().copyItemAtPath(bundlecascadePath!, toPath: cascadePath)
        }
    
        MasksWareHouse.dataSource = self
        MasksWareHouse.delegate = self
        
        centerImage.addSubview(statusLabelView)
        
        statusLabelView.translatesAutoresizingMaskIntoConstraints = false
        let topStatusLabelViewConstraints = statusLabelView.topAnchor.constraintEqualToAnchor(centerImage.topAnchor)
        let leftStatusLabelViewConstraints = statusLabelView.leftAnchor.constraintEqualToAnchor(centerImage.leftAnchor)
        let rightStatusLabelViewConstraints = statusLabelView.rightAnchor.constraintEqualToAnchor(centerImage.rightAnchor)
        let heightStatusLabelViewConstraints = statusLabelView.heightAnchor.constraintEqualToConstant(44.0)
        
        NSLayoutConstraint.activateConstraints([topStatusLabelViewConstraints, leftStatusLabelViewConstraints, rightStatusLabelViewConstraints, heightStatusLabelViewConstraints])
        
        view.layoutIfNeeded()
        
        statusLabelView.alpha = 0
    }
    
    func changeCenterImage()
    {
        rawROIInImage.removeAll()
        roiButtons.removeAll()
        processedROIInView.removeAll()
        isMasked.removeAll()
        lastActiveButtonIndex = 0
        currentActiveButtonIndex = 0
        
        rawROIInImage = faceDetection()
        for (var i = 0; i < rawROIInImage.count; i++)
        {
            processedROIInView.append(roiFitInUIView(rawROIInImage[i]))
        }
        createButtonOnROI(processedROIInView)
    }
    
    
    @IBOutlet var statusLabelView: UIView!
    @IBOutlet var statusInfo: UILabel!
    func changeStatus(text: String)
    {
        statusInfo.text = text
        
        statusLabelView.alpha = 1
            
        UIView.animateWithDuration(1){ ()->Void in
            self.statusLabelView.alpha = 0
        }
    }
    

    
    /*********************** Share Button end ***********************/
    @IBAction func onShare(sender: UIButton)
    {
        let activityController = UIActivityViewController(activityItems: [centerImage.image!], applicationActivities: nil)
        presentViewController(activityController, animated: true, completion: nil)
    }
    /*********************** Share Button end ***********************/
    
    
     
    /*********************** Filter Button begin ***********************/
    var roiButtons: [UIButton] = []
    var rawROIInImage: [CGRect] = []
    var processedROIInView: [CGRect] = []
    
    var currentActiveButtonIndex: Int = 0
    var lastActiveButtonIndex: Int = 0
    var isProcessed: Bool = false
    
    @IBOutlet var roiSelect: UIButton!
    @IBAction func onROISelect(sender: UIButton)
    {
        if (!isProcessed)
        {
            centerImage.alpha = 0.7
            isProcessed = true
            changeCenterImage()
            changeStatus("Face detection done...")
            
            if (!roiButtons.isEmpty)
            {
                roiButtons[currentActiveButtonIndex].layer.borderWidth = 1.5
            }
        }
        else if (currentActiveButtonIndex + 1 >= roiButtons.count && centerImage.alpha == 0.7 && !roiButtons.isEmpty)
        {
            centerImage.alpha = 1
            roiButtons[currentActiveButtonIndex].layer.borderWidth = 0
        }
        else if (isProcessed && !roiButtons.isEmpty)
        {
            centerImage.alpha = 0.7
            lastActiveButtonIndex = currentActiveButtonIndex
            currentActiveButtonIndex = (currentActiveButtonIndex + 1 >= roiButtons.count) ? 0 : (currentActiveButtonIndex + 1)
            
            roiButtons[lastActiveButtonIndex].layer.borderWidth = 0
            roiButtons[currentActiveButtonIndex].layer.borderWidth = 1.5
        }
        else
        {
            changeStatus("No face region of image detected")
        }
    }
    
    func faceDetection() -> [CGRect]
    {
        let roiRect: NSMutableArray = ocWrapper.FaceDetectionWithOpenCVCascade(centerImage.image);
        let Magnifying = CGFloat(0.3)
        var roiRects: [CGRect] = [];
        
        for (var index = 0; index < roiRect.count; index++)
        {
            var rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            roiRect[index].getValue(&rect)
            rect = CGRectMake(rect.minX - rect.width * Magnifying, rect.minY - rect.height * Magnifying, rect.width + rect.width * 2 * Magnifying, rect.height + rect.height * 2 * Magnifying)
            
            if (isAlreadyChangeMask(rect))
            {
                continue
            }
            else
            {
                roiRects.append(rect)
            }
        }
        return roiRects
    }
    
    func roiFitInUIView(unprocessedROI: CGRect) -> CGRect
    {
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let ImageViewWidth = UIScreen.mainScreen().bounds.width
        let ImageViewHeight = UIScreen.mainScreen().bounds.height - bottomStackView.bounds.height - statusBarHeight
        let ImageHeight = centerImage.image!.size.height
        let ImageWidth = centerImage.image!.size.width
        
        var Scaling: CGFloat
        if (ImageHeight / ImageViewHeight > ImageWidth / ImageViewWidth)
        {
            Scaling = ImageHeight / ImageViewHeight
            
            let blankWidth = (ImageViewWidth - ImageWidth / Scaling) / 2;
            return CGRectMake(unprocessedROI.minX / Scaling + blankWidth, unprocessedROI.minY / Scaling, unprocessedROI.width / Scaling, unprocessedROI.height / Scaling)
        }
        else
        {
            Scaling = ImageWidth / ImageViewWidth
            let blankHeight = (ImageViewHeight - ImageHeight / Scaling) / 2
            
            return CGRectMake(unprocessedROI.minX / Scaling, unprocessedROI.minY / Scaling + blankHeight + statusBarHeight, unprocessedROI.width / Scaling, unprocessedROI.height / Scaling)
        }
    }
    
    func createButtonOnROI(ROI: [CGRect])
    {
        for i in 0 ..< ROI.count
        {
            let button = UIButton(frame: ROI[i])
            button.layer.borderColor = UIColor.whiteColor().CGColor
            button.addTarget(self, action: Selector("RoiTapped:"), forControlEvents: .TouchUpInside)
            button.tag = i
            
            roiButtons.append(button)
            view.addSubview(button)
            
            isMasked.append(-1)
        }
    }
    
    func isAlreadyChangeMask(roi: CGRect) -> Bool
    {
        for processedROI in processedROIInView
        {
            let x11 = processedROI.minX, x12 = processedROI.maxX, y11 = processedROI.minY, y12 = processedROI.maxY
            let x21 = roi.minX, x22 = roi.maxX, y21 = roi.minY, y22 = roi.maxY
            
            let x_overlap = max(min(x12, x22) - max(x11, x21), 0)
            let y_overlap = max(min(y12, y22) - max(y11, y21), 0)
            
            if (x_overlap * y_overlap > min(roi.height * roi.width, processedROI.height * processedROI.width) * 0.5)
            {
                return true
            }
        }
        return false
    }
    
    func RoiTapped(button: UIButton)
    {
        for (var i = 0; i < roiButtons.count; i++)
        {

            if (button.tag == roiButtons[i].tag)
            {
                lastActiveButtonIndex = currentActiveButtonIndex
                currentActiveButtonIndex = i
                break
            }
        }
        roiButtons[lastActiveButtonIndex].layer.borderWidth = 0
        roiButtons[currentActiveButtonIndex].layer.borderWidth = 1.5
    }
    /*********************** Filter Button end ***********************/

     
    /*********************** Mask Button begin ***********************/
    @IBOutlet var maskButton: UIButton!
    @IBOutlet var MasksWareHouse: UICollectionView!
    @IBOutlet var saveOrCancelBar: UIView!
    
    var isMasked: [Int] = []
    var isProcessedRoi: [CGRect] = []
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return MasksDefault.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = MasksWareHouse.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        cell.backgroundView = UIImageView.init(image: UIImage.init(named: MasksDefault[indexPath.item]))
        cell.backgroundColor = .blackColor()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        clickOnSpecificMask(indexPath.item)
    }
    
    func clickOnSpecificMask(index: Int)
    {
        if (isProcessed && !roiButtons.isEmpty && centerImage.alpha == 0.7)
        {
            roiButtons[currentActiveButtonIndex].setImage(UIImage.init(named: MasksDefault[index]), forState: .Normal)
            isMasked[currentActiveButtonIndex] = index
            showCancelOrSaveBar()
        }
        else
        {
            changeStatus("Please first select some regions")
        }
    }
    
    func showCancelOrSaveBar()
    {
        view.addSubview(saveOrCancelBar)
        saveOrCancelBar.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraints = saveOrCancelBar.topAnchor.constraintEqualToAnchor(centerImage.topAnchor)
        let leftConstraints = saveOrCancelBar.leftAnchor.constraintEqualToAnchor(centerImage.leftAnchor)
        let rightConstraints = saveOrCancelBar.rightAnchor.constraintEqualToAnchor(centerImage.rightAnchor)
        let heightConstraints = saveOrCancelBar.heightAnchor.constraintEqualToConstant(32)
        
        NSLayoutConstraint.activateConstraints([topConstraints, leftConstraints, rightConstraints, heightConstraints])
        
        view.layoutIfNeeded()
    }
    
    func hideCancelOrSaveBar()
    {
        saveOrCancelBar.removeFromSuperview()
    }
    
    
    @IBAction func onMaskButton(sender: UIButton)
    {
        if sender.selected
        {
            hideMaskWareHouse()
            sender.selected = false
        }
        else
        {
            showMaskWareHouse()
            sender.selected = true
        }
    }
    
    func showMaskWareHouse()
    {
        view.addSubview(MasksWareHouse)
        
        MasksWareHouse.translatesAutoresizingMaskIntoConstraints = false
        let bottomMasksWareHouseConstraints = MasksWareHouse.bottomAnchor.constraintEqualToAnchor(bottomStackView.topAnchor)
        let leftMasksWareHouseConstraints = MasksWareHouse.leftAnchor.constraintEqualToAnchor(centerImage.leftAnchor)
        let rightMasksWareHouseConstraints = MasksWareHouse.rightAnchor.constraintEqualToAnchor(centerImage.rightAnchor)
        let heightMasksWareHouseConstraints = MasksWareHouse.heightAnchor.constraintEqualToConstant(55)
        
        NSLayoutConstraint.activateConstraints([bottomMasksWareHouseConstraints, leftMasksWareHouseConstraints, rightMasksWareHouseConstraints, heightMasksWareHouseConstraints])
        
        view.layoutIfNeeded()
    }
    func hideMaskWareHouse()
    {
        MasksWareHouse.removeFromSuperview()
    }
    
    @IBAction func onSave(sender: UIButton)
    {
        hideCancelOrSaveBar()
        centerImage.alpha = 1
        
        for (var i = 0; i < roiButtons.count; i++)
        {
            if (isMasked[i] >= 0)
            {
                roiButtons[i].setImage(UIImage.init(), forState: .Normal);
                isProcessedRoi.append(rawROIInImage[i])
                centerImage.image = ocWrapper.changeRoiOfImage(centerImage.image, roi: rawROIInImage[i], mask: UIImage.init(named: MasksDefault[isMasked[i]]))
            }
            roiButtons[i].layer.borderWidth = 0
            roiButtons[i].enabled = false
        }
        onMaskButton(maskButton)
        isProcessed = false
    }
    
    @IBAction func onCancel(sender: UIButton)
    {
        hideCancelOrSaveBar()
        for (var i = 0; i < roiButtons.count; i++)
        {
            if (isMasked[i] >= 0)
            {
                roiButtons[i].setImage(UIImage.init(), forState: .Normal)
            }
        }
    }
    
}
