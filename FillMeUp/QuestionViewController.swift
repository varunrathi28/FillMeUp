//
//  ViewController.swift
//  FillMeUp
//
//  Created by Varun Rathi on 19/11/17.
//  Copyright © 2017 vrat28. All rights reserved.
//

import UIKit
import ChameleonFramework

class QuestionViewController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var btnReplay:UIButton!
    
    
    @IBOutlet weak var viewPickerContainer:UIView!
    @IBOutlet weak var pickerView:UIPickerView!
    @IBOutlet weak var lblScore:UILabel!
    
    var currentActiveCell:Int?
    var arrSentences:[Sentence] = []
    var arrHints:[String] = [" "]
    
    // This gameInfo will manage user game difficults. as the user successfully answers all the answers , increase the level/ number of questions per level
    
    var gameInfo:GameLevel = {
        let gameLevel = GameLevel()
        return gameLevel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        self.automaticallyAdjustsScrollViewInsets = false
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableViewAutomaticDimension
        viewPickerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hidePickerWithoutAnimation()
        callWebServiceToFetchText()
        //testDummy()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pickerView.delegate = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setupNavBar()
    {
        navigationController?.navigationBar.barTintColor = FlatTeal()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.title = "Fill Me Up"
        
        let rightBarButton = UIBarButtonItem(title: "Submit", style: .done, target:self, action: #selector(btnSubmitClicked))
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func configurePicker()
    {
        DispatchQueue.main.async {
            self.pickerView.delegate = self
            self.pickerView.dataSource = self
        }
       
    }
    
    func refreshUI()
    {
        // set Pickerview datasources as the array of hints
        configurePicker()
        
        self.stopActivityIndicator()
        
        // Reload tableView on Dispatch Queue
        Utility.reloadTableViewOnMainThread(tableView: self.tableView)
        
    }
    
   func startActivityIndicator()
    {
        DispatchQueue.main.async {
            let activityIndicator = ActivityIndicator.shared
            activityIndicator.startLoader(on: self.view)
        }
        
    }
    
   func  stopActivityIndicator()
    {
        DispatchQueue.main.async {
            let activityIndicator = ActivityIndicator.shared
            activityIndicator.stopLoader()
        }
        
    }
    
    func callWebServiceToFetchText()
    {
        
        startActivityIndicator()
        let apiClient = APIClient()
        apiClient.get(urlString: URLConstants.kBaseURL) { (json, error, status) in
            if status == true {
                if let jsonStr = json["query"]["pages"][URLConstants.pageID]["extract"].string {
                    // Convert string -> [String]/ [Sentences]
                    let arrStrings = Utility.splitSentences(from: jsonStr, limit: self.gameInfo.questionCount)
                    // Convert Array of String array of Models
                    self.arrSentences = arrStrings.map({ (string) -> Sentence in
                        return Sentence(with: string)
                    })
                    
                    // Prepare sentences by grouping tags based on lexical analysis of sentence
                    let response =  WordJumble.prepareQuestions(sentences: self.arrSentences, with: self.gameInfo)
                    
                    // This will return Tuple of Manipulated sentences( a word would be removed from each text), and array of removed words, which we will use as Hint options
                    
                    if let hints = response.1 {
                       // self.arrSentences = processedSentences
                        self.arrHints = hints
                        self.refreshUI()
                    }
                    else
                    {
                        // Error parsing sentences
                    }
                }
                
            }
            
            else
            {
                self.stopActivityIndicator()
            }
        }
    }
    
    @IBAction func btnReplayClicked(sender:AnyObject) {
        callWebServiceToFetchText()
    }
    
    
    func btnSubmitClicked()
    {
        calculateScore()
        pushResultsScreen()
        
    }
    
    func calculateScore()
    {
        var score = 0
        for sentence in arrSentences {
            
            if let answer = sentence.answer {
                
                if sentence.missingText == answer {
                    
                    score = score + 1;
                    sentence.score = 1;
                }
                
            }
        }
        
        gameInfo.score = score
        
        // Check if all answers are correct, If Yes-> Increment Difficulty Level
        if score == gameInfo.questionCount {
            gameInfo.increaseLevel()
        }
    }
    
    func pushResultsScreen()
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier:StoryboardIdentifer.ResultsScreen) as! ResultsViewController
        vc.arrSentences = arrSentences
        vc.gameInfo = gameInfo
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - Picker functions
    
    @IBAction func pickerDoneButtonClicked(sender:UIBarButtonItem)
    {
        hidePicker()
        
    }
    
    func showPicker()
    {
        let pickerHeight = viewPickerContainer.frame.size.height
        let screenHeight = view.frame.size.height
        let offset = screenHeight - pickerHeight
        UIView.animate(withDuration: 0.2) {
            
            self.viewPickerContainer.frame = CGRect(x: 0, y: offset, width: self.viewPickerContainer.frame.size.width, height: self.viewPickerContainer.frame.size.height)
        }
    }
    
    func hidePicker()
    {
        UIView.animate(withDuration: 0.2) {
            self.viewPickerContainer.frame = CGRect(x: 0, y: self.view.frame.size.height, width: self.viewPickerContainer.frame.size.width, height: self.viewPickerContainer.frame.size.height)
        }
    }
    
    func hidePickerWithoutAnimation()
    {
        
        self.viewPickerContainer.frame = CGRect(x: 0, y: self.view.frame.size.height, width: self.viewPickerContainer.frame.size.width, height: self.viewPickerContainer.frame.size.height)
    }
    
    
}

// MARK:- TableView Methods
extension QuestionViewController:UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrSentences.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.QuestionCellId, for: indexPath) as! QuestionTableCell
        
        let sentence = arrSentences[indexPath.row]
        cell.sentence = sentence
        cell.delegate = self
        cell.index = indexPath.row
        cell.configureCell()
        return cell
    }
}

extension QuestionViewController:UIPickerViewDataSource
{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arrHints.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return arrHints[row]
    }
}
extension QuestionViewController:UIPickerViewDelegate
{
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let sentence = arrSentences[currentActiveCell!]
        let answer = arrHints[row]
        sentence.answer = answer
        
        let indexPath = IndexPath(item: currentActiveCell!, section: 0)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
}

extension QuestionViewController:QuestionCellDelegate {
    
    func cellTapped(at index: Int) {
        currentActiveCell = index
        showPicker()
    }
}

