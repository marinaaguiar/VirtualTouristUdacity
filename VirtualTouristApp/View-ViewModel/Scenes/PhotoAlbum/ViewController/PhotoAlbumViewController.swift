import UIKit
import Kingfisher
import CoreLocation

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var seeMoreButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var trashButton: UIButton!

    var viewModel: PhotoAlbumViewModelProtocol!

    var selectedPhotos: [String] = []
    var selectedPhotosIndex: [IndexPath] = []

    var selectedPhotosDic: [String: Int] = [:]
//    var selectedPhotosSet = Set<String, Int>()

    private let images: [UIImage] = Array(1...11).map { UIImage(named: String($0))! }
//    private var page: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.delegate = self
        viewModel.loadData()
        activityIndicator.isHidden = true
        trashButton.isHidden = true
        collectionView.collectionViewLayout = createLayout()
        collectionView.allowsMultipleSelection = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
//            viewModel.saveAlbum(imagesUrl: viewModel.imagesUrlString)
        }
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {

        let item = CompositionalLayout.createItem(
            width: .fractionalWidth(1),
            height: .fractionalHeight(1),
            spacing: 1)

        let group = CompositionalLayout.createGroup(
            aligment: .horizontal,
            width: .fractionalWidth(1),
            height: .absolute(200),
            item: item,
            count: 3)

        let section = NSCollectionLayoutSection(group: group)

        return UICollectionViewCompositionalLayout(section: section)
    }
    
    @IBAction func seeMoreButtonPressed(_ sender: UIButton) {
        collectionView.isScrollEnabled = false
        seeMoreButton.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        viewModel.loadMoreData()
    }

    @IBAction func trashButtonPressed(_ sender: Any) {
        
    }


    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: collectionView.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "SF", size: 15)
        messageLabel.sizeToFit()
        collectionView.backgroundView = messageLabel
    }

    func checkIfIsEmpty() {
        if viewModel.imagesUrlString.isEmpty {
            setEmptyMessage("There is no photos in the location")
            seeMoreButton.isEnabled = false
        } else {
            seeMoreButton.isEnabled = true
            setEmptyMessage("")
        }
    }

    func updateButtonsStatus() {
        if !selectedPhotos.isEmpty {
            seeMoreButton.isHidden = true
            trashButton.isHidden = false
        } else {
            seeMoreButton.isHidden = false
            trashButton.isHidden = true
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.imagesUrlString.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as? CollectionViewCell else {
            fatalError("Unexpected Index Path")
        }
        viewModel.updateImage(
            imageView: cell.cellImageView,
            imageUrl: viewModel.imagesUrlString[indexPath.row]
        )
        return cell
    }
}

    //MARK: - UiCollectionViewDelegate

extension PhotoAlbumViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPhoto = viewModel.imagesUrlString[indexPath.item]
        selectedPhotos.append(selectedPhoto)
        updateButtonsStatus()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let selectedPhoto = viewModel.imagesUrlString[indexPath.item]
        if selectedPhotos.contains(selectedPhoto) {
            selectedPhotos = selectedPhotos.filter { !$0.contains(selectedPhoto) }
        }
        updateButtonsStatus()
    }
}

    //MARK: - PhotoAlbumViewModelDelegate

extension PhotoAlbumViewController: PhotoAlbumViewModelDelegate {

    func didLoad() {
        let indexPath = IndexPath(item: viewModel.imagesUrlString.count - 15, section: 0)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.viewModel.isLoading {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.seeMoreButton.isHidden = false
                self.collectionView.isScrollEnabled = true
                self.collectionView.reloadData()
                self.checkIfIsEmpty()
                self.seeMoreButton.isEnabled = true
                self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
        }
    }

    func didLoadWithError() {
        //
    }
}


    //MARK: - CollectionViewCell

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
}
