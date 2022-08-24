import UIKit
import Kingfisher


//MARK: - CollectionViewCell

struct PhotoCell {
    let imageUrl: String?
}

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var checkMark: UIImageView!

    override var isSelected: Bool {
        didSet {
            if isSelected {
                checkMark.isHidden = false
                checkMark.image = UIImage(systemName: "checkmark.circle.fill")
                cellImageView.alpha = 0.5
            } else {
                checkMark.isHidden = true
                cellImageView.alpha = 1
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        isSelected = false
    }

    func fill(_ cell: PhotoCell) {
        if let urlString = cell.imageUrl,
           let url = URL(string: urlString) {

            cellImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
        }
    }
}
