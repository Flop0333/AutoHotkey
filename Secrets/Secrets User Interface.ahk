class SecretsUserInterface {

    static AskForValue(requestedSecret) {
        userInputSecretValue := InputBox("Secret: " requestedSecret.name "`nDescription: " . requestedSecret.description . "`n`nPlease provide a value`nCancel to leave empty.`n`nThis value will be saved to your local My Secrets.json file (git-ignored).`nIt is stored unencrypted on your machine.", "Secret value not set! " . requestedSecret.name, "w500 h250")

        if userInputSecretValue.Result = "Ok"
            return userInputSecretValue.Value
        Info("Canceled input for secret:`n" . requestedSecret.name, 5000)
        return ""
    }
}