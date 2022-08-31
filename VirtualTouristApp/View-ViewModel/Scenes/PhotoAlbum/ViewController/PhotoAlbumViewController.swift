import UIKit
import Kingfisher
import CoreLocation

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var toolBarActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var toolBarView: UIView!

    var viewModel: PhotoAlbumViewModelProtocol!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        navigationController?.isToolbarHidden = true
        updateActivityIndicator(loading: true)
        viewModel.refreshItems()
        viewModel.checkIfAlbumHasImages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        toolBarView.isHidden = true
        newCollectionButton.isHidden = true
        trashButton.isHidden = true
        toolBarActivityIndicator.isHidden = true
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
    
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        collectionView.isScrollEnabled = false
        updateToolBarButtons(loading: true)
        viewModel.updateAlbumCollection()
        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)

    }

    @IBAction func trashButtonPressed(_ sender: Any) {
        let deleteAlert = buildDeleteAlert {
            self.viewModel.deleteSelectedImages(indexPath: self.collectionView.indexPathsForSelectedItems!)
            self.collectionView.reloadData()
            self.updateButtonsStatus()
        }
        self.show(deleteAlert, sender: nil)
    }

    func buildDeleteAlert(onDelete: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "", message: "Are you sure you want to delete this photos permanently?", preferredStyle: .actionSheet
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak alert] _ in
            onDelete()
        }
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        return alert
    }

    func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.allowsMultipleSelection = true
    }

    func setEmptyMessage(_ status: Bool) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: collectionView.bounds.size.height))
        if status == true {
            messageLabel.isHidden = false
            messageLabel.text = "There is no photos in the location"
            messageLabel.textColor = .black
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont(name: "SF", size: 15)
            messageLabel.sizeToFit()
            collectionView.backgroundView = messageLabel
        } else {
            messageLabel.isHidden = true
        }
    }

    func updateButtonsStatus() {
        if collectionView.indexPathsForSelectedItems != [] {
            toolBarView.isHidden = false
            newCollectionButton.isHidden = true
            trashButton.isHidden = false
        } else {
            toolBarView.isHidden = false
            newCollectionButton.isHidden = false
            trashButton.isHidden = true
        }
    }

    func updateActivityIndicator(loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }

    func updateToolBarButtons(loading: Bool) {
        toolBarView.isHidden = false
        if loading {
            newCollectionButton.isHidden = true
            toolBarActivityIndicator.isHidden = false
            toolBarActivityIndicator.startAnimating()
        } else {
            toolBarActivityIndicator.stopAnimating()
            toolBarActivityIndicator.isHidden = true
            newCollectionButton.isHidden = false
            newCollectionButton.isEnabled = true 
        }
    }

    func hideToolBarView() {
        newCollectionButton.isHidden = true
        toolBarView.isHidden = true
    }

    func presentErrorAlert(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }

    func cell(_ collectionView: UICollectionView, indexPath: IndexPath, photoCell: PhotoCell) -> UICollectionViewCell {

        let cell = collectionView.dequeCell(CollectionViewCell.self, indexPath)
        cell.fill(photoCell)
        return cell
    }
}

//MARK: - UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cell(collectionView, indexPath: indexPath, photoCell: viewModel.fillCell(atIndexPath: indexPath.row))
    }
}

    //MARK: - UiCollectionViewDelegate

extension PhotoAlbumViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateButtonsStatus()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateButtonsStatus()
    }
}

    //MARK: - PhotoAlbumViewModelDelegate

extension PhotoAlbumViewController: PhotoAlbumViewModelDelegate {

    func didLoad() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.viewModel.isLoading {
                self.updateActivityIndicator(loading: false)
                self.updateToolBarButtons(loading: false)
                self.collectionView.isScrollEnabled = true
                self.collectionView.reloadData()
                self.newCollectionButton.isEnabled = true
                self.setEmptyMessage(false)
            }
        }
    }

    func didLoadWithNoImages() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateActivityIndicator(loading: false)
            self.hideToolBarView()
            self.setEmptyMessage(true)
            self.collectionView.isScrollEnabled = false
            self.collectionView.reloadData()
        }
    }

    func didLoadWithError(_ error: Error) {
        presentErrorAlert(error)
        hideToolBarView()
    }
}



