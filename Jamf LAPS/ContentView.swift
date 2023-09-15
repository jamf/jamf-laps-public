//
//  ContentView.swift
//  Jamf LAPS
//  Copyright 2023, Jamf
//

import SwiftUI
import os.log

struct ContentView: View {
    @AppStorage("jamfURL") var jamfURL: String = ""
    @AppStorage("userName") var userName: String = ""
    @AppStorage("useAPIRoles") var useAPIRoles: Bool = false
//    @AppStorage("savePassword") var savePassword: Bool = false
    
    @State private var password = ""
    
    //Settings
    @State private var autoDeployEnabled = false
    @State private var passwordRotationTime = ""
    @State private var autoRotateEnabled = false //Added for v2
    @State private var autoRotateExpirationTime = "" //Used to be autoExpirationTime under v1
    
    @State private var saveSettingsButtonDisabled = true
    
    @State private var passwordRotationTimeChanged = false
    @State private var autoExpirationTimeChanged = false
    @State private var enableLAPSChanged = false
    
    //Alert
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    //Password
    @State private var serialNumber = ""
    @State private var lapsUserName = ""
    @State private var lapsPassword = ""
    @State private var fetchPassewordButtonDisabled = true
    
    @State private var showActivity = false

    
    var body: some View {
        
        HStack {
            Toggle("Enable LAPS", isOn: $autoDeployEnabled)
                .padding([.leading,.trailing])
                .toggleStyle(.switch)
                .onChange(of: autoDeployEnabled) { newValue in
                    saveSettingsButtonDisabled = false
                    if enableLAPSChanged {
                        saveSettingsButtonDisabled = true
                        enableLAPSChanged = false
                    }
                }
            Spacer()
        }
        
        HStack {
            Toggle("Enable Auto Rotate", isOn: $autoRotateEnabled)
                .padding([.leading,.trailing])
                .toggleStyle(.switch)
                .onChange(of: autoRotateEnabled) { newValue in
                    saveSettingsButtonDisabled = false
                    if enableLAPSChanged {
                        saveSettingsButtonDisabled = true
                        enableLAPSChanged = false
                    }
                }
            Spacer()
        }

        HStack(alignment: .center) {
            
            VStack(alignment: .trailing, spacing: 12.0) {
                Text("Password Rotation Time:")
                Text("Auto Expiration Time:")
            }
            
            VStack(alignment: .leading, spacing: 7.0) {
                TextField("" , text: $passwordRotationTime, onEditingChanged: { (changed) in
                    passwordRotationTimeChanged = changed
                })
                .textFieldStyle(.roundedBorder)
                .onChange(of: passwordRotationTime) { newValue in
                    if passwordRotationTimeChanged {
                        saveSettingsButtonDisabled = false
                    } else {
                        saveSettingsButtonDisabled = true
                    }
                }
                
                TextField("" , text: $autoRotateExpirationTime, onEditingChanged: { (changed) in
                    autoExpirationTimeChanged = changed
                })
                .textFieldStyle(.roundedBorder)
                .onChange(of: autoRotateExpirationTime) { newValue in
                    if autoExpirationTimeChanged {
                        saveSettingsButtonDisabled = false
                    } else {
                        saveSettingsButtonDisabled = true
                    }
                }
            }
        }
        .padding([.leading,.trailing])
        .alert(isPresented: self.$showAlert,
               content: {
            self.showCustomAlert()
        })
        
        HStack(alignment: .center) {
            Button("Fetch Settings") {
                Task {
                    fetchPassword()
                    await fetchSettings()
                    
                }
            }
            Button("Save") {
                Task {
                    await saveSettings()
                }
            }
            .disabled(saveSettingsButtonDisabled)
        }
        
        //Get Password
        Divider()
        HStack {
            Text("Fetch Local Administration Password")
            Spacer()
        }
        .padding([.leading,.trailing, .bottom])
        HStack(alignment: .center) {
            
            VStack(alignment: .trailing, spacing: 12.0) {
                Text("Serial Number:")
                Text("Username:")
                Text("Password:")
            }
            
            VStack(alignment: .leading, spacing: 7.0) {
                TextField("" , text: $serialNumber)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: serialNumber) { newValue in
                        
                        if !serialNumber.isEmpty && !lapsUserName.isEmpty {
                            fetchPassewordButtonDisabled = false
                        } else {
                            fetchPassewordButtonDisabled = true
                        }
                    }
                
                TextField("" , text: $lapsUserName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: lapsUserName) { newValue in
                        if !serialNumber.isEmpty && !lapsUserName.isEmpty {
                            fetchPassewordButtonDisabled = false
                        } else {
                            fetchPassewordButtonDisabled = true
                        }
                        
                    }
                Text(lapsPassword)
                    .textSelection(.enabled)
            }
        }
        .padding([.leading,.trailing])
        .task {
            let defaults = UserDefaults.standard
            useAPIRoles = defaults.bool(forKey: "useAPIRoles")
            let jamfURL = defaults.string(forKey: "jamfURL") ?? ""
            if jamfURL.isEmpty {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .onAppear {
//            if savePassword  {
                fetchPassword()
//            }
        }
        
        HStack(alignment: .center) {
            Button("Fetch Password") {
                Task {
                    fetchPassword()
                    await fetchLAPSPassword()
                }
            }
            .disabled(fetchPassewordButtonDisabled)
            ProgressView()
                    .scaleEffect(0.5)
                    .opacity(showActivity ? 1 : 0)
        }
        
    }
    
    func fetchPassword() {
        let credentialsArray = Keychain().retrieve(service: "com.jamf.jamf-laps")
        if credentialsArray.count == 2 {
            //userName = credentialsArray[0]
            password = credentialsArray[1]
        }
        
    }
    
    func showCustomAlert() -> Alert {
        return Alert(
            title: Text(alertTitle),
            message: Text(alertMessage),
            dismissButton: .default(Text("OK"))
        )
    }
    
    func fetchLAPSPassword() async {
        showActivity = true

        let jamfPro = JamfProAPI(username: userName, password: password)
        let (bearerToken, _) = await jamfPro.getToken(jssURL: jamfURL, base64Credentials: jamfPro.base64Credentials, useAPIRole: useAPIRoles)
        
        
        guard let bearerToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            showActivity = false
            return
        }
        
        
        let (computerID, computerResponse) = await jamfPro.getComputerID(jssURL: jamfURL, authToken: bearerToken, serialNumber: serialNumber)
        
        
        guard let computerID else {
            alertMessage = "Could not find this computer, please check the serial number."
            alertTitle = "Computer Record"
            showAlert = true
            showActivity = false
            return
        }
        
        let (managementID, managementIDResponse) = await jamfPro.getComputerManagementID(jssURL: jamfURL, authToken: bearerToken, id: computerID)
        
        guard let managementID else {
            alertMessage = "Could not retrieve the managementID, please check the serial number."
            alertTitle = "Management ID"
            showAlert = true
            showActivity = false
            return
        }
        
        let (password, passwordResponse) = await jamfPro.getLAPSPassword(jssURL: jamfURL, authToken: bearerToken, managementId: managementID, username: lapsUserName)
        
        guard let password else {
            alertMessage = "Could not retrieve the password, please check the serial number and laps user name."
            alertTitle = "Password"
            showAlert = true
            showActivity = false
            return
        }
        lapsPassword = password
        showActivity = false

        
    }
    
    func saveSettings() async {
        let jamfPro = JamfProAPI(username: userName, password: password)
        let (bearerToken, _) = await jamfPro.getToken(jssURL: jamfURL, base64Credentials: jamfPro.base64Credentials, useAPIRole: useAPIRoles)
        
        guard let bearerToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            return
        }
        
        guard let passwordRotationTimeInt = Int(passwordRotationTime) else {
            alertMessage = "The Password Rotation Time does not appear to be valid amount of seconds."
            alertTitle = "Password Rotation Time"
            showAlert = true
            return
        }
        
        guard let autoRotateExpirationTimeInt = Int(autoRotateExpirationTime) else {
            alertMessage = "The Auto Rotate Expiration Time does not appear to be valid amount of seconds."
            alertTitle = "Auto Expiration Time"
            showAlert = true
            return
        }

        
        
        let lapsSettings = LAPSSettings(autoDeployEnabled: autoDeployEnabled, passwordRotationTime: passwordRotationTimeInt, autoRotateEnabled: autoRotateEnabled, autoRotateExpirationTime: autoRotateExpirationTimeInt)
        
        let response = await jamfPro.saveSettings(jssURL: jamfURL, authToken: bearerToken, lapsSettings: lapsSettings)
        
        guard let response = response, response == 200 else {
            alertMessage = "Could not save LAPS settings. Error \(response)"
            alertTitle = "Save Error"
            showAlert = true
            return
        }
        
        saveSettingsButtonDisabled = true
        
    }
    
    
    func fetchSettings() async {
        passwordRotationTimeChanged = false
        autoExpirationTimeChanged = false
        enableLAPSChanged = false
        
        let jamfPro = JamfProAPI(username: userName, password: password)
        let (bearerToken, _) = await jamfPro.getToken(jssURL: jamfURL, base64Credentials: jamfPro.base64Credentials, useAPIRole: useAPIRoles)
        
        
        
        guard let bearerToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            return
        }
        let (lapsSettings, response) = await jamfPro.fetchSettings(jssURL: jamfURL, authToken: bearerToken)
        
        guard let response = response, response == 200 else {
            alertMessage = "Could not fetch LAPS settings. Error \(response)"
            alertTitle = "Fetch Error"
            showAlert = true
            return
        }
        
        if let lapsSettings = lapsSettings {
            if autoDeployEnabled != lapsSettings.autoDeployEnabled {
                enableLAPSChanged = true
            }
            autoDeployEnabled = lapsSettings.autoDeployEnabled
            autoRotateEnabled = lapsSettings.autoRotateEnabled
            passwordRotationTime = String(lapsSettings.passwordRotationTime)
            autoRotateExpirationTime = String(lapsSettings.autoRotateExpirationTime)
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
