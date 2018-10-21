//
//  ViewController.swift
//  ForesightDemo
//
//  Created by Jonathan Zia on 10/10/18.
//  Copyright © 2018 Enabyl Inc. All rights reserved.
//

import UIKit
import CoreML
import SwiftyForesight

class ViewController: UIViewController {
    
    // MARK: Global Variables (General)
    // Setting the "Generate Data" button as the active button
    var activeButtons = [ActiveButton]()
    // Default status field text
    let defaultStatusText = "Select Action"
    // Number of feature vectors
    let numFeatures = 5
    // Feature vector length
    let featureLength = 50
    // Target vector length
    let targetLength = 3
    // User ID
    let userID = UUID().uuidString
    
    // MARK: Global Variables (Foresight)
    var cloudManager: CloudManager?     // CloudManager Object
    var myData: LibraData?              // LibraData Object
    var myModel: FeedforwardModel?      // LibraModel Object
    // From awsconfiguration.json
    let identityID = "us-east-1:ec8a76fe-0f69-4d17-a479-b8e75c5ad9ad"   // AWS Identity ID
    let writeBucket = "foresightdemo-userfiles-mobilehub-2116500124"    // AWS Write Bucket Name
    let readBucket = "foresightdemo-deployments-mobilehub-2116500124"   // AWS Read Bucket Name
    let tableName = "foresightdemo-mobilehub-2116500124-ForesightDemo"  // AWS DynamoDB Table Name
    
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
        
        // Initialize LibraModel
        // Set filepath for LibraModel
        let modelURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("myModel.mlmodel")
        myModel = FeedforwardModel(modelClass: MLModel(), numInputFeatures: 5, localFilepath: modelURL, withManager: cloudManager!)
        
        // Set table name
        CloudManager.tableName = tableName
        
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
        for _ in 0..<numFeatures {
            // Set feature vector placeholder
            var featureVector = [Double]()
            for _ in 0..<featureLength {
                featureVector.append(Double.random(in: 0..<1))
            }
            // Append feature vector to feature array
            features.append(featureVector)
        }
        
        // Populate label array
        for _ in 0..<featureLength {
            // Set label vector placeholder ([1, 0, ... , 0])
            var labelVector = [1.0]; labelVector.append(contentsOf: Array<Double>(repeating: Double(0), count: targetLength-1))
            // Append label vector to label array
            labels.append(labelVector)
        }
        
        // Format current date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMhhmmss"
        
        // Generate metadata
        let myMetadata = [Keys.hash: userID, Keys.range: formatter.string(from: Date())]
        
        // Feed arrays to LibraData object
        myData?.addFeatures(features)
        myData?.addLabels(labels)
        
        // Feed metadata to LibraData object
        myData?.addMetadata(withAttributes: myMetadata)
        
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
        
        group.wait()
        // Once the data has been saved locally, upload it to remote S3 write bucket
        myData?.uploadDataToRemote(fromLocalPath: url, completion: { (success) in
            // Notify user of status
            if success {
                DispatchQueue.main.async {
                    self.statusField.text = "Uploaded Data (1)"
                }
            } else {
                DispatchQueue.main.async {
                    self.statusField.text = "Error Uploading Data"
                }
            }
        })
        
        // Upload metadata to DynamoDB
        myData?.uploadMetadataToRemote(completion: { (success) in
            if success{
                DispatchQueue.main.async {
                    self.statusField.text = "Uploaded Data (2)"
                }
            } else {
                DispatchQueue.main.async {
                    self.statusField.text = "Error Uploading Metadata"
                }
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
        
        // Fetch model from remote server
        myModel?.fetchFromRemote(withRemoteFilename: "\(userID)_model0.mlmodel", completion: { (success) in
            if success {
                // Update status field
                self.statusField.text = "Retrieved Model"
                // Set all buttons to active
                if !self.activeButtons.contains(.predict) {
                    self.activeButtons.append(.predict)
                    self.setActiveButtons(toButtons: self.activeButtons)
                }
            }
        })
        
    }
    
    // Generating Predictions
    @IBAction func generatingPredictionsButtonPress(_ sender: UIButton) {
        
        // Generating predictions using downloaded model
        
        // Ensure that the "Generate Prediction" button is active
        guard activeButtons.contains(.predict) else {
            // Print error and return
            print("Invalid Request: No model for prediction."); return
        }
        
        // Ensure that a model is compiled
        guard (myModel?.compiled)! else {
            // Print error and return
            print("Invalid Request: No model for prediction."); return
        }
        
        // Set status field
        statusField.text = "Generating Predictions..."
        
        // Generate predictions
        // Set inputs
        var inputVector = [Double]()
        for _ in 0..<numFeatures {
            inputVector.append(Double.random(in: 0..<1))
        }
        
        // Make prediction
        let prediction = (myModel?.predict(forInputs: inputVector, availableGPU: true))!
        print(prediction)   // Print to console
        
        // Set status field
        if prediction[2].doubleValue > 0.5 {
            statusField.text = "Generated Predictions (001)"
        }
        else if prediction[1].doubleValue > 0.5 {
            statusField.text = "Generated Predictions (010)"
        }
        else if prediction[0].doubleValue > 0.5 {
            statusField.text = "Generated Predictions (100)"
        } else {
            statusField.text = "Error Generating Predictions"
        }
        
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
