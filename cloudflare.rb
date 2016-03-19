#!/usr/bin/env ruby

require 'yaml'
require 'rest-client'
require 'public_suffix'
require 'resolv'

# Determines if the DNS record has propogated yet
def _hasDNSPropogated(name, token)
    servers = _getYAMLKey("CF_DNS_SERVERS").split(',')
    
    txt = Resolv::DNS.open(:nameserver => servers) do |dns|
      records = dns.getresources(name, Resolv::DNS::Resource::IN::TXT)
      records.empty? ? nil : records.map(&:data).join(",")
    end

    txt = txt.split(',')
    txt.each do |record|
        if (record == token)
            return true
        end
    end

    return false
end

# Helper method to get Cloudflare Headers
def _getCFHeaders()
    return {
        :"X-Auth-Email" => _getYAMLKey("CF_EMAIL"),
        :"X-Auth-Key"   => _getYAMLKey("CF_KEY"),
        :"Content-Type" => 'application/json',
    }
end

# Loads the yaml file and returns the requested constant
def _getYAMLKey(name)
    begin
        yaml = YAML.load_file("/var/lib/acme/cloudflare.yml")
        begin
            return yaml[name]
        rescue Exception => e
            raise " + Variable missing in YAML file"
        end
    rescue Exception => e
        puts " + #{e.message}"
        raise " + Unable to load /var/lib/acme/cloudflare.yml"
    end
end

# Retrieves the Cloudflare zone_id for a given domain
def _getZoneID(domain)
    zone = PublicSuffix.parse(domain)
    
    response = RestClient.get "https://api.cloudflare.com/client/v4/zones?name=#{zone.domain}", _getCFHeaders()
    
    if response.code != 200
        raise " + Unable to fetch zone from Cloudflare"
    end
    return JSON.parse(response)["result"][0]["id"]
end

# Retrieves the ID of the TXT record
def _getTXTRecordID(zoneId, name, token)
     response = RestClient.get "https://api.cloudflare.com/client/v4/zones/#{zoneId}/dns_records?type=TXT&name=#{name}&content=#{token}", _getCFHeaders()
     
     if response.code != 200
        raise " + Unable to fetch zone from Cloudflare"
     end
     
     return JSON.parse(response)["result"][0]["id"]
end

# challenge-dns-start
def challengednsstart(domain, token)
    zoneId =  _getZoneID(domain)
    name   = "_acme-challenge.#{domain}"
    
    begin
        response = RestClient::Request.execute(
            :method => :post,
            :url => "https://api.cloudflare.com/client/v4/zones/#{zoneId}/dns_records",
            :payload => {
                :type              => 'TXT',
                :name              => name,
                :content           => token,
                :ttl               => 1
            }.to_json,
            :headers => _getCFHeaders())
        
        puts " + TXT record created..."
        puts " + Waiting 10s for DNS to propogate..."
        sleep 10
        
        while _hasDNSPropogated(name, token) == false
            puts " + Waiting an additional 30s for DNS to propogate..."
            sleep 30
        end
    rescue => e
        raise " + #{e.message}"
    end
    
    return true
end

# challenge-dns-stop
def challengednsstop(domain, token)
    zoneId   =  _getZoneID(domain)
    name     = "_acme-challenge.#{domain}"
    recordId = _getTXTRecordID(zoneId, name, token)
    
    response = RestClient.delete "https://api.cloudflare.com/client/v4/zones/#{zoneId}/dns_records/#{recordId}", _getCFHeaders
    
    if response.code != 200
        raise " + Unable to fetch zone from Cloudflare"
    end
    
    return true
end

# Script entrypoint
if __FILE__ == $0
  
  # Retrieve all the arguements
  hook_stage    = ARGV[0]
  domain        = ARGV[1]
  token         = ARGV[2]
  txt_challenge = ARGV[3]
  
  # Try the execute the method
  begin
    functionName = hook_stage.tr('-', '')
    if !self.send(functionName, domain, token)
        raise " + Method not supported" 
    end
  rescue Exception => e
    puts e.message
    exit(1)
  end
end