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
    
    // MARK: Global Variables
    // Setting the "Generate Data" button as the active button
    var activeButtons = [ActiveButton]()
    // Default status field text
    let defaultStatusText = "Select Action"
    
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
        
        // Set status field
        statusField.text = "Uploaded Data"
        
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
