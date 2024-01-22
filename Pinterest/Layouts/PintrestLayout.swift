/// Copyright (c) 2024 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

protocol PinterestLayoutDelegate: AnyObject {
  func collectionView(_ collectionView: UICollectionView,
                      heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat
}

class PintrestLayout: UICollectionViewLayout {
  
  // Delegate to get the details such as photo actual height
  weak var delegate: PinterestLayoutDelegate?
  
  // Important properties numberOfColumns, cellPadding to layout things
  private let numberOfColumns = 2
  private let cellPadding: CGFloat = 6
  
  // Cache so I dont do these complicated calculations all the time
  private var cache: [UICollectionViewLayoutAttributes] = []
  
  // Height of the total content
  private var contentHeight: CGFloat = 0
  
  //Width of the total content, notice how we took into account insets of content, but have assumed no distance between cells
  private var contentWidth: CGFloat {
    guard let collectionView = collectionView else {
      return 0
    }
    let insets = collectionView.contentInset
    return collectionView.bounds.width - (insets.left + insets.right)
  }
  
  // Content size of the collection view
  override var collectionViewContentSize: CGSize {
    return CGSize(width: self.contentWidth, height: self.contentHeight)
  }
  
  // Fucntion recieved from collection view to start preparing layout attributes when layout is invalidated
  override func prepare() {

    super.prepare()
    cache.removeAll() // When invalidating the layout
    
    // We only proceed if cache is empty and collection view is not nil
    guard self.cache.isEmpty, let collectionView = collectionView else { return }
    
    // This is the space we have for column recieved after subtracting insets from collection view check above
    let columnWidth = self.contentWidth / CGFloat(self.numberOfColumns)
    
    var xOffset: [CGFloat] = []
    
    
    // We gonna iterate throgh each of the columns we are going to place, and calculate xOffset for each column
    for column in 0..<self.numberOfColumns {
      xOffset.append(CGFloat(column) * columnWidth)
    }
    
    // We are now calculating yOffset
    var column = 0
    var yOffset: [CGFloat] = .init(repeating: 0, count: self.numberOfColumns)
    
    // We iterate through each item in section to calculate offsets
    // If we have more than 1 sections we might want to do it for each section in a loop
    for item in 0..<collectionView.numberOfItems(inSection: 0) {
      let indexPath = IndexPath(item: item, section: 0)
        
      // Asking delegate for exact height of the image. Defaulting to 180  if no value is supplied by delegate, or if delegate is nil
      let photoHeight = self.delegate?.collectionView(
        collectionView,
        heightForPhotoAtIndexPath: indexPath) ?? 180
      
      // We now calculate actual height needed to add the image, notice we are appending top and bottom padding
      let height = self.cellPadding * 2 + photoHeight
      
      // Based on xOffset and yOffest and height we are now ready for frame calculation
      let frame = CGRect(x: xOffset[column],
                         y: yOffset[column],
                         width: columnWidth,
                         height: height)
      // Inseting this makes sure we have padding space on all sides, also observe how we took into account added height before and then inset it. So previously we added padding to height
      // For example if photoheight was 80, we added 10 + 10 padding then inset by 10, getting image hieght again??????
      
      let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding) //Smaller frame
      
      
      // We setup the layout attributes
      let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      attributes.frame = insetFrame
      self.cache.append(attributes)
        
      // Now we set the content height with new calculated frame, as it might have changed the situation. Also notice the frame used in this calculation is using the normal frame with padding and is not using the inset frame, inset frame is just for the content and the padded frame is for collection view layout, because essentially padding is the responsibility of the collection view layout and not content
      self.contentHeight = max(self.contentHeight, frame.maxY)
      
      // This upadted yOffset is essentially the frame.height
      yOffset[column] = yOffset[column] + height
      
      // We add next item to the next column until we are done with all the items
      column = column < (numberOfColumns - 1) ? (column + 1) : 0
    }

  }
  
  override func layoutAttributesForElements(in rect: CGRect)
      -> [UICollectionViewLayoutAttributes]? {
    var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
    
    // Loop through the cache and look for items in the rect that intersects
    for attributes in cache {
      if attributes.frame.intersects(rect) {
        visibleLayoutAttributes.append(attributes)
      }
    }
    return visibleLayoutAttributes
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath)
      -> UICollectionViewLayoutAttributes? {
    return cache[indexPath.item]
  }
  
}
