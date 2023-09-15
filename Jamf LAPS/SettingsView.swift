//
//  SettingsView.swift
//  Jamf LAPS
//
//  Copyright 2023, Jamf

import SwiftUI

struct SettingsView: View {
    @AppStorage("jamfURL") var jamfURL: String = ""
    @AppStorage("userName") var userName: String = ""
    @AppStorage("useAPIRoles") var useAPIRoles: Bool = false
    
    @State var userNameLabel: String = "Username:"
    @State var passwordLabel: String = "Password:"

//    @AppStorage("savePassword") var savePassword: Bool = false
    @State private var password = ""
    
    var body: some View {
        VStack(alignment: .trailing){
            HStack(alignment: .center) {
                
                VStack(alignment: .trailing, spacing: 12.0) {
                    Text("Jamf Server URL:")
                    Text(userNameLabel)
                    Text(passwordLabel)
                }
                
                VStack(alignment: .leading, spacing: 7.0) {
                    TextField("https://your-jamf-server.com" , text: $jamfURL)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Your Jamf Pro admin user name" , text: $userName)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Your password" , text: $password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: password) { newValue in
                            savePasswordToKeychain()
                        }
                }
            }
            .padding()
            HStack() {
                Spacer()
                Toggle(isOn: $useAPIRoles) {
                    Text("Use API Roles and Clients")
                }
                .toggleStyle(.checkbox)
                .onChange(of: useAPIRoles) { newValue in
                    print("useAPIRoles toggled")
                    if useAPIRoles {
                        userNameLabel = "Client ID:"
                        passwordLabel = "Client Secret:"
                    } else {
                        userNameLabel = "Username:"
                        passwordLabel = "Password:"
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            let defaults = UserDefaults.standard
            userName = defaults.string(forKey: "userName") ?? ""
            jamfURL = defaults.string(forKey: "jamfURL") ?? ""
            useAPIRoles = defaults.bool(forKey: "useAPIRoles")
            if useAPIRoles {
                userNameLabel = "Client ID:"
                passwordLabel = "Client Secret:"
            } else {
                userNameLabel = "Username:"
                passwordLabel = "Password:"
            }
                let credentialsArray = Keychain().retrieve(service: "com.jamf.jamf-laps")
                if credentialsArray.count == 2 {
                    userName = credentialsArray[0]
                    password = credentialsArray[1]
                }
        }
    }
    
    func savePasswordToKeychain() {
        DispatchQueue.global(qos: .background).async {
            Keychain().save(service: "com.jamf.jamf-laps", account: userName, data: password)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
