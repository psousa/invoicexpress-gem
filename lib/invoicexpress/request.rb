module Invoicexpress
  module Request

    def delete(path, options={})
      request(:delete, path, options).body
    end

    def get(path, options={})
      repsonse = request(:get, path, options).body
    end

    def patch(path, options={})
      request(:patch, path, options).body
    end

    def post(path, options={})
      request(:post, path, options).body
    end

    def put(path, options={})
      request(:put, path, options).body
    end

    private

    # Executes the request, checking if it was successful
    #
    # @return [Boolean] True on success, false otherwise
    def boolean_from_response(method, path, options={})
      request(method, path, options).status == 204
    rescue Invoicexpress::NotFound
      false
    end

    def request(method, path, options={})
      token = options.delete(:api_key)  || api_key
      url   = options.delete(:endpoint) || (api_endpoint % account_domain)
      klass = options.delete(:klass) || raise(ArgumentError, "Need a HappyMapper class to parse")

      conn_options = {
        :url   => url,
        :klass => klass
      }

      response = connection(conn_options).send(method) do |request|
        request.headers['Accept'] = options.delete(:accept) || 'application/xml'

        case method
        when :get, :delete, :head
          request.options.params_encoder = Faraday::FlatParamsEncoder
          request.url(path, options)
        when :patch, :post, :put
          request.headers['Content-Type'] = "application/xml; charset=utf-8"

          request.path = path
          request.body = options[:body].to_xml unless options.empty?
        end
      end

      response
    rescue Faraday::ConnectionFailed => e
      unless e.message.match(/getaddrinfo/).nil?
        raise Invoicexpress::BadAddress.new,
          "Did you forget to set your account_name? Error: #{e.message}"
      end

      raise e
    end

    def account_domain
      account_name || screen_name
    end
  end
end
