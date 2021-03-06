module SpreedlyCore
  # Base class for all SpreedlyCore API requests
  class Base
    include HTTParty
    
    # Net::HTTP::Options is configured to not have a body.
    # Lets give it the body it's always dreamed of
    Net::HTTP::Options::RESPONSE_HAS_BODY = true
    
    format :xml

    # timeout requests after 10 seconds
    default_timeout 10

    base_uri "https://spreedlycore.com/v1"

    def self.configure(login, secret, gateway_token)
      @@login = login
      self.basic_auth(login, secret)
      @@gateway_token = gateway_token
    end

    def self.login; @@login; end
    def self.gateway_token; @@gateway_token; end

    # make a post request to path
    # If the request succeeds, provide the respones to the &block
    def self.verify_post(path, options={}, &block)
      verify_request(:post, path, options, 200, 422, &block)
    end

    # make a put request to path
    # If the request succeeds, provide the respones to the &block
    def self.verify_put(path, options={}, &block)
      verify_request(:put, path, options,  &block)
    end

    # make a get request to path
    # If the request succeeds, provide the respones to the &block
    def self.verify_get(path, options={}, &block)
      verify_request(:get, path, options, 200, &block)
    end

    # make an options request to path
    # If the request succeeds, provide the respones to the &block
    def self.verify_options(path, options={}, &block)
      verify_request(:options, path, options, 200, &block)
    end

    # make a request to path using the HTTP method provided as request_type
    # *allowed_codes are passed in, verify the response code (200, 404, etc)
    # is one of the allowed codes.
    # If *allowed_codes is empty, don't check the response code, but set an instance
    # variable on the object created in the block containing the response code.
    def self.verify_request(request_type, path, options, *allowed_codes, &block)
      begin 
        response = self.send(request_type, path, options)
      rescue Timeout::Error, Errno::ETIMEDOUT => e
        raise TimeOutError.new("Request to #{path} timed out. Is Spreedly Core down?")
      end
        
      if allowed_codes.any?
        if allowed_codes.include?(response.code)
          block.call(response)
        else
          raise "Error retrieving #{path}. Got status of #{response.code}. Expected status to be in #{allowed_codes.join(",")}\n#{response.body}"
        end
      else
        block.call(response).tap do |obj|
          obj.instance_variable_set("@http_code", response.code)
        end
      end
    end

    # Given a hash of attrs, assign instance variables using the hash key as the
    # attribute name and hash value as the attribute value
    #
    def initialize(attrs={})
      attrs.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
      # errors may be nil, empty, a string, or an array of strings. 
      @errors = if @errors.nil? || @errors["error"].blank?
                  []
                elsif @errors["error"].is_a?(String)
                  [@errors["error"]]
                else
                  @errors["error"]
                end
    end
  end

end
