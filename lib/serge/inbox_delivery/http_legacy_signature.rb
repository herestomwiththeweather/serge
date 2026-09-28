module Serge
  class InboxDelivery
    class HttpLegacySignature
      def initialize(request)
        InboxDelivery.logger.info "#{self.class}##{__method__}"
        @request = request
      end

      def created_time
        Time.httpdate(@request.headers['Date']).utc if @request.headers['Date'].present?
      rescue ArgumentError => e
        raise Serge::SignatureVerificationError, "Invalid Date header: #{e.message}"
      end

      def expires_time
        # just take default
        nil
      end

      def missing_signature_parameters
        nil
      end

      def key_id
        InboxDelivery.logger.info "#{self.class}##{__method__}"
        signature_header&.dig('keyId')
      end

      def verify_signature_strength!
        signed_headers = signature_header['headers']
        raise Serge::SignatureVerificationError, 'Date header must be signed' unless signed_headers.split.include?('date')
        raise Serge::SignatureVerificationError, 'Digest header must be signed' unless signed_headers.split.include?('digest')
      end

      def verify_body_digest!
        InboxDelivery.logger.info "#{self.class}##{__method__}"
        raise Serge::SignatureVerificationError, 'Digest header missing' unless @request.headers.key?('Digest')
        digests = @request.headers['Digest'].split(',').map { |digest| digest.split('=', 2) }.map { |key, value| [key.downcase, value] }
        sha256  = digests.assoc('sha-256')
        if sha256.nil?
          InboxDelivery.logger.info "#{self.class}##{__method__} Error. offered algorithms: #{digests.map(&:first).join(', ')}"
          raise Serge::SignatureVerificationError, "Only SHA-256 is supported in Digest header."
        end

        return if body_digest == sha256[1]

        digest_size = begin
          Base64.strict_decode64(sha256[1].strip).length
        rescue ArgumentError
          raise Serge::SignatureVerificationError, "Invalid Digest value. The provided Digest value is not a valid base64 string. Given digest: #{sha256[1]}"
        end

        if digest_size != 32
          raise Serge::SignatureVerificationError, "Invalid Digest value. The provided Digest value is not a SHA-256 digest. Given digest: #{sha256[1]}"
        end

        raise Serge::SignatureVerificationError, "Invalid Digest value. Computed SHA-256 digest: #{body_digest}; given: #{sha256[1]}"
      end

      def verify(signature, comparison_string, public_key)
        InboxDelivery.logger.info "#{self.class}##{__method__}"

        key = OpenSSL::PKey::RSA.new(public_key)
        result = key.verify(OpenSSL::Digest::SHA256.new, signature, comparison_string)
        if !result
          InboxDelivery.logger.info "#{self.class}##{__method__} Error verifying signature"
        end

        result
      end

      def verified?(public_key)
        headers   = signature_header['headers']
        signature = Base64.decode64(signature_header['signature'])

        comparison_string = FediSignature.signing_string(headers.split) do |header|
          '(request-target)' == header ? "post #{@request.path}" : @request.headers[capitalized(header)]
        end

        return true if verify(signature, comparison_string, public_key)
      end

      private

      def body_digest
        @body_digest ||= Digest::SHA256.base64digest(request_body)
      end

      def request_body
        @request_body ||= @request.raw_post
      end

      def capitalized(text)
        text.gsub(/(?:^|-)([a-z])/) { |m| m.upcase }
      end

      def signature_header
        return @signature_header if defined?(@signature_header)

        @signature_header = FediSignature.parse_header(@request.headers['Signature'])
        if @signature_header.nil?
          InboxDelivery.logger.info "#{self.class}##{__method__} Error. malformed Signature header from #{@request.remote_ip}: #{@request.headers['Signature'].inspect}"
        else
          header_values = "algorithm: #{@signature_header['algorithm']}, headers: #{@signature_header['headers']}"
          header_values << ", expires: #{@signature_header['expires']}" if @signature_header['expires'].present?
          InboxDelivery.logger.info "#{self.class}##{__method__} #{header_values}"
        end

        @signature_header
      end
    end
  end
end
