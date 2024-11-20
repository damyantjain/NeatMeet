import UIKit

class LandingPagePickerViewController: UIViewController {

    let landingPagePickerView = LandingPagePickerView()
    var options: [String]
    var selectedOption: String
    var notificationName: NSNotification.Name

    init(
        options: [String], selectedOption: String,
        notificationName: NSNotification.Name
    ) {
        self.options = options
        self.selectedOption = selectedOption
        self.notificationName = notificationName
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = landingPagePickerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        landingPagePickerView.pickerView.delegate = self
        landingPagePickerView.pickerView.dataSource = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done", style: .done, target: self,
            action: #selector(doneButtonTapped))

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel", style: .plain, target: self,
            action: #selector(cancelButtonTapped))

        if let selectedIndex = options.firstIndex(of: selectedOption) {
            landingPagePickerView.pickerView.selectRow(
                selectedIndex, inComponent: 0, animated: false)
        }
    }

    @objc private func doneButtonTapped() {
        NotificationCenter.default.post(
            name: notificationName, object: selectedOption)

        dismiss(animated: true)
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LandingPagePickerViewController: UIPickerViewDelegate,
    UIPickerViewDataSource
{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(
        _ pickerView: UIPickerView, numberOfRowsInComponent component: Int
    ) -> Int {
        return options.count
    }

    func pickerView(
        _ pickerView: UIPickerView, titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        return options[row]
    }

    func pickerView(
        _ pickerView: UIPickerView, didSelectRow row: Int,
        inComponent component: Int
    ) {
        selectedOption = options[row]
    }
}