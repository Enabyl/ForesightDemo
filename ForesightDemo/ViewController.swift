//
//  ViewController.swift
//  ForesightDemo
//
//  Created by Jonathan Zia on 10/10/18.
//  Copyright © 2018 Enabyl Inc. All rights reserved.
//

import UIKit
import SwiftyForesight

class ViewController: UIViewController {
    
    // MARK: Global Variables (General)
    // Setting the "Generate Data" button as the active button
    var activeButtons = [ActiveButton]()
    // Default status field text
    let defaultStatusText = "Select Action"
    // Number of feature vectors
    let numFeatures = 3
    // Feature vector length
    let featureLength = 5
    // Target vector length
    let targetLength = 3
    // User ID
    let userID = UUID().uuidString
    
    // MARK: Global Variables (Foresight)
    var cloudManager: CloudManager?     // CloudManager Object
    var myData: LibraData?              // LibraData Object
    var myModel: LibraModel?            // LibraModel Object
    // From awsconfiguration.json
    let identityID = "MyIdentityID"     // AWS Identity ID
    let writeBucket = "MyWriteBucket"   // AWS Write Bucket Name
    let readBucket = "MyReadBucket"     // AWS Read Bucket Name
    
    // MARK: Outlets
    @IBOutlet weak var generateDataButton: UIButton!
    @IBOutlet weak var uploadDataButton: UIButton!
    @IBOutlet weak var retrieveModelButton: UIButton!
    @IBOutlet weak var generatePredictionButton: UIButton!
    @IBOutlet weak var statusField: UILabel!
    
    // MARK: Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Format buttons
        generateDataButton.layer.cornerRadius = 10
        uploadDataButton.layer.cornerRadius = 10
        retrieveModelButton.layer.cornerRadius = 10
        generatePredictionButton.layer.cornerRadius = 10
        
        // Set status text
        statusField.text = defaultStatusText
        
        // Add "Generate Data" to active buttons
        if !activeButtons.contains(.generate) {
            activeButtons.append(.generate)
            setActiveButtons(toButtons: activeButtons)
        }
        
        // Initialize CloudManager
        cloudManager = CloudManager(identityID: identityID, userID: userID, writeBucket: writeBucket, readBucket: readBucket)
        
        // Initialize LibraData
        myData = LibraData(hasTimestamps: false, featureVectors: numFeatures, labelVectorLength: targetLength, withManager: cloudManager!)
        
    }

    // MARK: Action Buttons
    // Generating Data
    @IBAction func generateDataButtonPress(_ sender: UIButton) {
        
        // Generate example data for uploading to Enabyl cloud
        
        // Ensure that the Generate Data button is active
        guard activeButtons.contains(.generate) else {
            // Print error and return
            print("Invalid Request: Cannot generate data."); return
        }
        
        // Set status field
        statusField.text = "Generating Data..."
        
        // Define feature and label placeholders
        var features = [[Double]]()
        var labels = [[Double]]()
        
        // Populate feature array
        for i in 0..<numFeatures {
            // Set feature vector placeholder
            let featureVector = Array<Double>(repeating: Double(i), count: featureLength)
            // Append feature vector to feature array
            features.append(featureVector)
        }
        
        // Populate label array
        for i in 0..<featureLength {
            // Set label vector placeholder
            let labelVector = Array<Double>(repeating: Double(i), count: targetLength)
            // Append label vector to label array
            labels.append(labelVector)
        }
        
        // Feed arrays to LibraData object
        myData?.addFeatures(features)
        myData?.addLabels(labels)
        
        // Set status field
        statusField.text = "Generated Data"
        
        // Add "Upload Data" to active buttons
        if !activeButtons.contains(.upload) {
            activeButtons.append(.upload)
            setActiveButtons(toButtons: activeButtons)
        }
        
    }
    
    // Uploading Data
    @IBAction func uploadDataButtonPress(_ sender: UIButton) {
        
        // Formatting and uploading data to Enabyl cloud
        
        // Ensure that the "Upload Data" button is active
        guard activeButtons.contains(.upload) else {
            // Print error and return
            print("Invalid Request: No data to upload."); return
        }
        
        // Set status field
        statusField.text = "Uploading Data..."
        
        // Initialize placeholder for data URL
        var url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        
        // Format data
        
        let group = DispatchGroup(); group.enter()
        myData?.formatData(completion: { (success, data, dataURL) in
            // Capture URL in closure
            url = dataURL; group.leave()
        })
        
        // Update the status field
        group.wait()
        statusField.text = "Uploaded Data"
        
        // Once the data has been saved locally, upload it to remote S3 write bucket
        myData?.uploadDataToRemote(fromLocalPath: url, completion: { (success) in
            // Notify user of status
            if success {
                self.statusField.text = "Uploaded Data"
            } else {
                self.statusField.text = "Error Uploading Data"
            }
        })

        // Add "Retrieve Model" to active buttons
        if !activeButtons.contains(.retrieve) {
            activeButtons.append(.retrieve)
            setActiveButtons(toButtons: activeButtons)
        }
        
    }
    
    // Retrieving Model
    @IBAction func retrieveModelButtonPress(_ sender: UIButton) {
        
        // Fetching model from Enabyl cloud
        
        // Ensure that the "Retrieve Data" button is active
        guard activeButtons.contains(.retrieve) else {
            // Print error and return
            print("Invalid Request: No model to retrieve."); return
        }
        
        // Set status field
        statusField.text = "Retrieving Model..."
        
        // Set status field
        statusField.text = "Retrieved Model"
        
        // Set all buttons to active
        if !activeButtons.contains(.predict) {
            activeButtons.append(.predict)
            setActiveButtons(toButtons: activeButtons)
        }
        
    }
    
    // Generating Predictions
    @IBAction func generatingPredictionsButtonPress(_ sender: UIButton) {
        
        // Generating predictions using downloaded model
        
        // Ensure that the "Generate Prediction" button is active
        guard activeButtons.contains(.predict) else {
            // Print error and return
            print("Invalid Request: No model for prediction."); return
        }
        
        // Set status field
        statusField.text = "Generating Predictions..."
        
        // Set status field
        statusField.text = "Generated Predictions"
        
    }
    
    // Reset
    @IBAction func resetButtonPress(_ sender: UIButton) {
        
        // Set "Generate Data" as only active button
        activeButtons = [.generate]
        setActiveButtons(toButtons: activeButtons)
        
        // Reset text field text
        statusField.text = defaultStatusText
        
    }
    
    // MARK: Supporting Functions
    // Setting active button
    func setActiveButtons(toButtons buttons: [ActiveButton]) {
        
        // Determine which button is active and reformat buttons accordingly
        // First, set all button backgrounds to inactive color
        let inactiveColor = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
        generateDataButton.backgroundColor = inactiveColor
        uploadDataButton.backgroundColor = inactiveColor
        retrieveModelButton.backgroundColor = inactiveColor
        generatePredictionButton.backgroundColor = inactiveColor
        
        // For each active button, set the foreground color to the active color
        for element in buttons {
            switch element {
            case .generate:
                generateDataButton.backgroundColor = #colorLiteral(red: 0, green: 0.3285208941, blue: 0.5748849511, alpha: 1)
            case .upload:
                uploadDataButton.backgroundColor = #colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1)
            case .retrieve:
                retrieveModelButton.backgroundColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
            case .predict:
                generatePredictionButton.backgroundColor = #colorLiteral(red: 0.8446564078, green: 0.5145705342, blue: 1, alpha: 1)
            }
        }
        
    }
    
}

// MARK: Supporting Structures
// Enumeration for different buttons
enum ActiveButton {
    case generate   // Generate Data
    case upload     // Upload Data
    case retrieve   // Retrieve Model
    case predict    // Generate Prediction
}
