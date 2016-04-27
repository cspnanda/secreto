require 'savon'
require 'nokogiri'


class Secreto

  def initialize(wsdl, ssl_verify_mode, ssl_version)
    @@wsdl=wsdl
    @@ssl_verify_mode=ssl_verify_mode
    @@ssl_version=ssl_version
    client = Savon.client(wsdl: @@wsdl, ssl_verify_mode: :none, ssl_version: :TLSv1)
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
end
