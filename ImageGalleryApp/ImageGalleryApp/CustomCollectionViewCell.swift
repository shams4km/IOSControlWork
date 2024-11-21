import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    // UI элементы для ячейки
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.frame = contentView.bounds
        contentView.addSubview(imageView)
    }
}
