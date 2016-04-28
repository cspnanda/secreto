# Secreto

Secreto is a gem to get password information from Thycotic Secret Server

## Installation

```ruby
gem install secreto
```

## Usage

```ruby
require 'secreto'

username = "username"
password = "password"
ad = "Active Directory Name" 
secretserver = "Secret Server"
secretServer = Secreto.new('https://' + secretserver + '/SecretServer/webservices/SSWebService.asmx?WSDL', ':none', ':TLSv1')
token = secretServer.Authenticate(username,password,ad)
puts secretServer.GetSecretByHostName("name of item to search","Machine")
puts secretServer.createSecret("Folder Name","Password","Name",["Resource","Username","Password","Notes"],["Resource Name","root","password","This is secret"])
```
