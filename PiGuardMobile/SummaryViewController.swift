//
//  SummaryViewController.swift
//  PiGuardMobile
//
//  Created by Stefano Vettor on 02/04/16.
//  Copyright © 2016 Stefano Vettor. All rights reserved.
//

import UIKit
import Charts
import PiGuardKit

enum SegueIdentifier: String {
    case MotionPictures = "motionPictures"
    case Settings = "settings"
}

class SummaryViewController: UIViewController {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var humidityIcon: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var temperatureIcon: UIImageView!
    @IBOutlet weak var co2Icon: UIImageView!
    @IBOutlet weak var co2Label: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var pressureIcon: UIImageView!
    
    @IBOutlet weak var cameraImage: UIImageView!
    @IBOutlet weak var playStopButton: UIButton!
    @IBOutlet weak var onOffButton: UIButton!
    @IBOutlet weak var surveillanceButton: UIButton!
    
    
    
    @IBOutlet weak var temperatureChart: LineChartView!
    @IBOutlet weak var humidityChart: LineChartView!
    @IBOutlet weak var pressureChart: LineChartView!
    @IBOutlet weak var co2Chart: BarChartView!
    
    @IBOutlet weak var alarmButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    fileprivate let viewModel = SummaryViewModel()
    fileprivate var streamingController: MjpegStreamingController?
    fileprivate let disposeBag = DisposablesBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeViewModel()
        initializeStreamingController()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshViewModel), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        if SettingsManager.sharedInstance.settingsLoaded {
            refreshViewModel()
        } else {
            performSegue(withIdentifier: SegueIdentifier.Settings.rawValue, sender: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        streamingController?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshViewModel() {
        viewModel.loadStatus()
        viewModel.loadData()
    }
    
    func initializeViewModel() {
        viewModel.date.observe { [unowned self] in
            self.dateLabel.text = $0
        }.addToDisposablesBag(disposeBag)
        
        viewModel.time.observe { [unowned self] in
            self.timeLabel.text = $0
        }.addToDisposablesBag(disposeBag)
        
        viewModel.picture.observe { [unowned self] in
            self.cameraImage.image = $0
        }.addToDisposablesBag(disposeBag)
        
        viewModel.temperature.observe { [unowned self] in
            if let tempText = $0 {
                self.temperatureLabel.text = tempText
                self.temperatureLabel.alpha = 1.0
                self.temperatureIcon.alpha = 1.0
            } else {
                self.temperatureLabel.alpha = 0.0
                self.temperatureIcon.alpha = 0.0
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.humidity.observe { [unowned self] in
            if let humText = $0 {
                self.humidityLabel.text = humText
                self.humidityLabel.alpha = 1.0
                self.humidityIcon.alpha = 1.0
            } else {
                self.humidityLabel.alpha = 0.0
                self.humidityIcon.alpha = 0.0
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.pressure.observe { [unowned self] in
            if let pressText = $0 {
                self.pressureLabel.text = pressText
                self.pressureLabel.alpha = 1.0
                self.pressureIcon.alpha = 1.0
            } else {
                self.pressureLabel.alpha = 0.0
                self.pressureIcon.alpha = 0.0
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.co2.observe { [unowned self] in
            if let co2Text = $0 {
                self.co2Label.text = co2Text
                self.co2Label.alpha = 1.0
                self.co2Icon.alpha = 1.0
            } else {
                self.co2Label.alpha = 0.0
                self.co2Icon.alpha = 0.0
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.temperatureHistory.observe { [unowned self] in
            if $0.isEmpty {
                self.temperatureChart.isHidden = true
            } else {
                self.temperatureChart.isHidden = false
                self.setupLineChart(self.temperatureChart, withLineColor: UIColor.red, andName: "temperature", andData: $0)
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.humidityHistory.observe { [unowned self] in
            if $0.isEmpty {
                self.humidityChart.isHidden = true
            } else {
                self.humidityChart.isHidden = false
                self.setupLineChart(self.humidityChart, withLineColor: UIColor.blue, andName: "humidity", andData: $0)
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.pressureHistory.observe { [unowned self] in
            if $0.isEmpty {
                self.pressureChart.isHidden = true
            } else {
                self.pressureChart.isHidden = false
                self.setupLineChart(self.pressureChart, withLineColor: UIColor.cyan, andName: "pressure", andData: $0)
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.co2History.observe { [unowned self] in
            if $0.isEmpty {
                self.co2Chart.isHidden = true
            } else {
                self.co2Chart.isHidden = false
                self.setupBarChart(self.co2Chart, withBarColor: UIColor.lightGray, andName: "co2", andData: $0)
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.motionHistory.observe { [unowned self] in
            if $0.isEmpty {
                self.alarmButtonItem.isEnabled = false
                self.alarmButtonItem.tintColor = UIColor.gray
                self.alarmButtonItem.removeBadge()
            } else {
                self.alarmButtonItem.isEnabled = true
                self.alarmButtonItem.tintColor = UIColor.red
                self.alarmButtonItem.addBadge(number: 1, withOffset: CGPoint(x: 10, y: 10))
            }
        }.addToDisposablesBag(disposeBag)
        
        viewModel.systemOn.observe { [unowned self] in
            let imageName = $0 ? "activeOnIcon" : "activeOffIcon"
            self.onOffButton.setBackgroundImage(UIImage(named: imageName), for: UIControlState())
        }.addToDisposablesBag(disposeBag)
        
        viewModel.surveillanceOn.observe { [unowned self] in
            let imageName = $0 ? "surveillanceOnIcon" : "surveillanceOffIcon"
            self.surveillanceButton.setBackgroundImage(UIImage(named: imageName), for: UIControlState())
        }.addToDisposablesBag(disposeBag)
        
        viewModel.errorHandler = { [unowned self] in
            let message: String
            if let error = $0 as? PiGuardError {
                switch error {
                case .emptyResponseError:
                    message = "The response from the server was empty"
                case .settingsMissing:
                    message = "Missing settings"
                default:
                    message = "Unkown error"
                }
            } else {
                let error = $0 as NSError
                message = error.localizedDescription
            }
            DispatchQueue.main.async {
                self.diaplayAlertMessage(message)
            }
        }
    }
    
    func initializeStreamingController() {
        streamingController = MjpegStreamingController(imageView: cameraImage)
        streamingController?.didStartLoading = {
            self.activityIndicator.startAnimating()
        }
        streamingController?.didFinishLoading = {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func setupLineChart(_ chart: LineChartView, withLineColor lineColor: UIColor, andName name: String, andData data: [(Double, String)]) {
        var dataEntries = [ChartDataEntry]()
        var xVals = [String]()
        for (i, e) in data.enumerated() {
            dataEntries.append(ChartDataEntry(x: Double(i), y: e.0))
            xVals.append("\(e.1)")
        }
        
        let chartDataSet = LineChartDataSet(values: dataEntries, label: name)
        chartDataSet.circleRadius = 3.0
        chartDataSet.lineWidth = 1.0
        chartDataSet.drawCircleHoleEnabled = false
        chartDataSet.setColor(lineColor)
        //chartDataSet.setCircleColor(UIColor.redColor())
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.lineWidth = 2.0
        chartDataSet.drawValuesEnabled = false
        chartDataSet.mode = .cubicBezier
        
        
        chart.highlightPerTapEnabled = false
        chart.highlightPerDragEnabled = false
        //temperatureChart.setScaleMinima(CGFloat(2.0), scaleY: CGFloat(1.0))
        chart.rightAxis.enabled = false
        //temperatureChart.drawGridBackgroundEnabled = false
        //temperatureChart.leftAxis.drawGridLinesEnabled = false
        
        /*chart.leftAxis.valueFormatter = NumberFormatter()
        chart.leftAxis.valueFormatter?.maximumFractionDigits = 0*/
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        //temperatureChart.xAxis.enabled = false
        chart.descriptionText = ""
        chart.legend.position = .aboveChartRight
        
        let chartData = LineChartData(dataSet: chartDataSet)
        chart.data = chartData
        chart.animate(xAxisDuration: 2.0)
    }
    
    func colorForCO2ppm(_ ppm: Int) -> UIColor {
        if ppm > 600 {
            return UIColor.yellow
        } else if ppm > 1000 {
            return UIColor.orange
        } else if ppm > 1500 {
            return UIColor.red
        } else {
            return UIColor.gray
        }
    }
    
    func setupBarChart(_ chart: BarChartView, withBarColor barColor: UIColor, andName name: String, andData data: [(Int, String)]) {
        var dataEntries = [BarChartDataEntry]()
        var xVals = [String]()
        //var barColors = [UIColor]()
        for (i, e) in data.enumerated() {
            dataEntries.append(BarChartDataEntry(x: Double(i), y: Double(e.0)))
            xVals.append("\(e.1)")
            //barColors.append(colorForCO2ppm(e.0))
        }
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: name)
        chartDataSet.setColor(barColor)
        chartDataSet.drawValuesEnabled = false
        //chartDataSet.colors = barColors
        
        chart.highlightPerTapEnabled = false
        chart.highlightPerDragEnabled = false
        chart.rightAxis.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.descriptionText = ""
        chart.legend.position = .aboveChartRight
        
        let chartData = BarChartData(dataSet: chartDataSet)
        chart.data = chartData
        chart.animate(xAxisDuration: 2.0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifierForSegue(segue) {
        case .MotionPictures:
            if let vc = segue.destination as? MotionPicturesViewController {
                vc.motions = viewModel.motionHistory.value
                alarmButtonItem.removeBadge()
            }
        case .Settings:
            if let vc = segue.destination as? SettingsViewController {
                vc.completionHandler = refreshViewModel
            }
        }
        
    }
    
    func segueIdentifierForSegue(_ segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier,
            let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
                fatalError("Invalid segue identifier \(segue.identifier).") }
        
        return segueIdentifier
    }
    
    func diaplayAlertMessage(_ message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func playAndStop(_ sender: AnyObject) {
        guard let streamingController = streamingController,
            let streamingURL = viewModel.streamingURL else { return }
        
        if streamingController.isPlaying() {
            streamingController.stop()
            playStopButton.setBackgroundImage(UIImage(named: "play"), for: UIControlState())
            playStopButton.setBackgroundImage(UIImage(named: "playHighlight"), for: .highlighted)
            playStopButton.setBackgroundImage(UIImage(named: "playHighlight"), for: .selected)
        } else {
            streamingController.play(url: streamingURL)
            playStopButton.setBackgroundImage(UIImage(named: "stop"), for: UIControlState())
            playStopButton.setBackgroundImage(UIImage(named: "stopHighlight"), for: .highlighted)
            playStopButton.setBackgroundImage(UIImage(named: "stopHighlight"), for: .selected)
        }
        
    }
    
    @IBAction func takeSnapshot(_ sender: AnyObject) {
        PiGuardKit.command(.Snapshot).wait(forSeconds: 2.0)
        .then { [unowned self] _ in self.viewModel.loadData() }
    }
    
    @IBAction func startAndStop(_ sender: AnyObject) {
        let command: CommandType = viewModel.systemOn.value ? .Stop : .Start
        PiGuardKit.command(command).then(PiGuardKit.systemStatusFromJson).then(viewModel.prepareStatus)
    }
    
    @IBAction func surveillanceOnAndOff(_ sender: AnyObject) {
        let command: CommandType = viewModel.surveillanceOn.value ? .Monitor : .Surveil
        PiGuardKit.command(command).then(PiGuardKit.systemStatusFromJson).then(viewModel.prepareStatus)
    }

}

