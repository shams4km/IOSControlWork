import UIKit
import CoreImage

class ImageGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // UI элементы
    private var collectionView: UICollectionView!
    private var segmentedControl: UISegmentedControl!
    private var progressView: UIProgressView!
    private var resultLabel: UILabel!
    private var startButton: UIButton!
    
    // Данные
    private var images: [UIImage] = []
    private var filteredImages: [UIImage?] = []
    private var task: Task<Void, Error>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImages()
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: "CustomCell")
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // UISegmentedControl
        segmentedControl = UISegmentedControl(items: ["Параллельно", "Последовательно"])
        segmentedControl.selectedSegmentIndex = 0
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        ])
        
        // UIButton
        startButton = UIButton(type: .system)
        startButton.setTitle("Начать вычисления", for: .normal)
        startButton.addTarget(self, action: #selector(startCalculations), for: .touchUpInside)
        view.addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 10),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // UILabel
        resultLabel = UILabel()
        resultLabel.text = "Результат: -"
        resultLabel.textAlignment = .center
        view.addSubview(resultLabel)
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 10),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        // UIProgressView
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    private func loadImages() {
        for i in 1...10 {
            if let image = UIImage(named: "image\(i)") {
                images.append(image)
            }
        }
        filteredImages = Array(repeating: nil, count: images.count)
    }
    
    @objc private func startCalculations() {
        progressView.progress = 0
        resultLabel.text = "Результат: -"
        
        task?.cancel()  // Отмена предыдущей задачи, если она существует
        let isParallel = segmentedControl.selectedSegmentIndex == 0
        
        if isParallel {
            // Параллельное выполнение
            task = Task {
                var progress = 0.0
                await withTaskGroup(of: Void.self) { group in
                    for i in 1...20 {
                        group.addTask {
                            let factorial = await self.calculateFactorial(of: i) // Добавлено self.
                            // Обновление UI на главном потоке
                            await MainActor.run {
                                self.resultLabel.text = "Факториал \(i): \(factorial)" // Добавлено self.
                                progress += 0.05
                                self.progressView.progress = Float(progress) // Добавлено self.
                            }
                        }
                    }
                    // Ожидание завершения всех задач
                    await group.waitForAll()
                }
            }
        } else {
            // Последовательное выполнение
            task = Task {
                var progress = 0.0
                for i in 1...20 {
                    if Task.isCancelled { break }
                    let factorial = self.calculateFactorial(of: i) // Добавлено self.
                    
                    // Обновление UI на главном потоке
                    await MainActor.run {
                        self.resultLabel.text = "Факториал \(i): \(factorial)" // Добавлено self.
                        progress += 0.05
                        self.progressView.progress = Float(progress) // Добавлено self.
                    }
                    
                    // Задержка
                    try await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
    }


    
    private func calculateFactorial(of number: Int) -> Int {
        return (1...number).reduce(1, *)
    }
    
    private func applyFilter(to image: UIImage) -> UIImage? {
        let context = CIContext()
        guard let ciImage = CIImage(image: image),
              let filter = CIFilter(name: "CISepiaTone") else { return nil }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCollectionViewCell
        cell.imageView.image = filteredImages[indexPath.item] ?? images[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
}
