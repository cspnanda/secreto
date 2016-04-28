require 'savon'
require 'nokogiri'
require 'crack'
require 'json'

class Secreto

  def initialize(wsdl, ssl_verify_mode, ssl_version)
    @@wsdl=wsdl
    @@ssl_verify_mode=ssl_verify_mode
    @@ssl_version=ssl_version
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1)
    @@secretTemplates = []
  end

  def Authenticate(username, password, domain)
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1)

    response = client.call(:authenticate, message: {
      username: username,
      password: password,
      organization: "",
      domain: domain 
    })

    @@token = response.to_hash[:authenticate_response][:authenticate_result][:token]
    getSecretTemplates()
    return @@token
  end

  def GetTokenIsValid
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1)
    response = client.call(:get_token_is_valid, message: {
      token: @@token
    })

    return response
  end

  def GetSecret(secretId)
	thesame = lambda { |key| key }	
    
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1, convert_request_keys_to: :none) #, convert_response_tags_to: thesame)
    response = client.call(:get_secret, message: {
      token: @@token,
      secretId: secretId,
    })
    doc = Nokogiri::XML.parse(response.to_xml)
    items = doc.xpath('//foo:SecretItem', 'foo' =>  'urn:thesecretserver.com')
    node = Hash.new
    node["password"] = getField(items,"Password")
    node["username"] = getField(items,"Username")
    node["host"] = getField(items,"Machine")
    return node
  end

  def getField(items,field)
    for item in items
      for child in item.children
        if child.content == field
            for child1 in item.children
              if child1.name == "Value"
                return child1.content
              end
            end
        end
      end
    end
  end

  def UpdateSecret(secret)
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1)
	# Nokogiri is stripping the 'xsi' prefix which is required, and it also puts a 'default' prefix in, which is disallowed.
	fixedXml = secret.to_s.gsub! 'nil=', 'xsi:nil='
	fixedXml = fixedXml.gsub! 'default:',''

    response = client.call(:update_secret, xml: fixedXml)
    return response
  end  

  def WhoAmI
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1)
    response = client.call(:who_am_i, message: {
      token: @@token
    })
    return response
  end

  def VersionGet
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1)
    response = client.call(:version_get, message: {
      token: @@token
    })
    return response
  end
  def GetSecretByHostName(hostName,objectType)
	thesame = lambda { |key| hostName }	
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1, convert_request_keys_to: :none)
    response = client.call(:get_secrets_by_field_value, message: {
      token: @@token,
      fieldName: objectType,
      searchTerm: hostName,
    })
    doc = Nokogiri::XML.parse(response.to_xml)
    items = doc.xpath('//foo:Id', 'foo' =>  'urn:thesecretserver.com')
    if not items[0].nil?
      if not items[0].content.nil?
        return GetSecret(items[0].content)
      end
    end
  end
  def createFolder(folderName,parentFolder)
	thesame = lambda { |key| hostName }	
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1, convert_request_keys_to: :none)
    parent = getFolder(parentFolder)
    if parent.nil?
      print "Parent Folder " + parentFolder + " doesn't exist"
      return nil
    else
      response = client.call(:folder_create, message: {
        token: @@token,
        folderName: folderName,
        parentFolderId: parent["id"],
        folderTypeId: 1
      })
      doc = Nokogiri::XML.parse(response.to_xml)
      puts doc
    end
  end
  def getFolder(folderName)
	thesame = lambda { |key| hostName }	
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1, convert_request_keys_to: :none)
    response = client.call(:search_folders, message: {
      token: @@token,
      folderName: folderName,
    })
    doc = Nokogiri::XML.parse(response.to_xml)
    items = doc.xpath('//foo:Folder', 'foo' =>  'urn:thesecretserver.com')
    if not items[0].nil?
      node = Hash.new
      for child in items[0].children
        if child.name == "Name"
          node["name"] = child.content
        elsif child.name == "TypeId"
          node["typeId"] = child.content
        elsif child.name == "Id"
          node["id"] = child.content
        elsif child.name == "ParentFolderId"
          node["parentFolderId"] = child.content
        end
      end
      return node
    end
    return nil
  end

  def getSecretTemplates()
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1, convert_request_keys_to: :none)
    response = client.call(:get_secret_templates, message: {
      token: @@token,
    })
    doc = Nokogiri::XML.parse(response.to_xml)

    secretTemplates = doc.xpath('//foo:SecretTemplates', 'foo' =>  'urn:thesecretserver.com')
    myjson = Crack::XML.parse(secretTemplates.to_xml)
    @@secretTemplates = myjson["SecretTemplates"]["SecretTemplate"]
    return nil
  end

  def createSecret(folderName,secretType,secretName,fieldKeys,fieldValues)
    if fieldKeys.length != fieldValues.length
      print "For each key there should be a value [" + fieldKeys.join(",") + " != " + fieldValues.join(",") + "]\n"
      return nil
    end
    templateFields = nil
    templateId = nil
    @@secretTemplates.each { |x| 
      if x['Name'] == secretType
        templateFields = x['Fields']['SecretField']
        templateId = x['Id']
        break
      end
    }
    if templateFields.nil?
      print "secretType " + secretType + " is not available" + "\n"
      return nil
    else
      #puts templateFields
      fieldIds = []
      fieldKeys.each { |fkey|
        templateFields.each { |field|
          if field['DisplayName'] == fkey
            fieldIds.push(field['Id'])
          end
        }
      }
      if fieldIds.length != fieldKeys.length
        print "Not all secretField were found [" + fieldKeys.join(",") + "]\n"
        return nil
      end
      # All Found
    end
    secretFieldIds = "<ns1:secretFieldIds>"
    fieldIds.each { |fid|
      secretFieldIds = secretFieldIds + "<ns1:int>" + fid.to_s + "</ns1:int>"
    }
    secretFieldIds = secretFieldIds + "</ns1:secretFieldIds>"

    secretItemValues = "<ns1:secretItemValues>"
    fieldValues.each { |fval|
      secretItemValues = secretItemValues + "<ns1:string>" + fval.to_s + "</ns1:string>"
    }
    secretItemValues = secretItemValues + "</ns1:secretItemValues>"


    folderId=getFolder(folderName)
    if folderId.nil?
      print "Folder " + folderName + " is not found"
      return nil
    end
    xmlString = '<?xml version="1.0" encoding="utf-8"?>' +
      '<SOAP-ENV:Envelope xmlns:ns0="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="urn:thesecretserver.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
      '<SOAP-ENV:Header/>' +
      '  <ns0:Body>' +
      '    <ns1:AddSecret>' +
      '      <ns1:token><ns1:token>' + @@token.to_s + '</ns1:token>' + 
      '      <ns1:secretTypeId>' + templateId + '</ns1:secretTypeId>' + 
      '      <ns1:secretName>' + secretName + '</ns1:secretName>' + 
      secretFieldIds +
      secretItemValues +
      '      <ns1:folderId>' + folderId["id"] + '</ns1:folderId>' +
      '    </ns1:token>' +
      '    </ns1:AddSecret>' +
      '  </ns0:Body>' +
      '</SOAP-ENV:Envelope>'

    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1)
    response = client.call(:add_secret, xml: xmlString)
    puts response.to_xml
  end
end
