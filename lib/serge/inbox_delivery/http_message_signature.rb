require "linzer/rack"

module Serge
  class InboxDelivery
    class HttpMessageSignature
      REQUIRED_PARAMETERS = %w(keyid created).freeze

      def initialize(request)
        InboxDelivery.logger.info "#{self.class}##{__method__}"
        @request = request
        @linzer_signature = Linzer::Signature.build({
          'signature-input' => @request.headers['signature-input'],
          'signature' => @request.headers['signature'],
        })
      rescue Linzer::Error => e
        raise Serge::SignatureVerificationError, e.message
      end

      def created_time
        Time.at(@linzer_signature.parameters['created'].to_i).utc
      rescue ArgumentError => e
        raise Serge::SignatureVerificationError, "Invalid Date header: #{e.message}"
      end

      def expires_time
        Time.at(@linzer_signature.parameters['expires'].to_i).utc if @linzer_signature.parameters['expires'].present?
      rescue ArgumentError => e
        raise Serge::SignatureVerificationError, "Invalid Date header: #{e.message}"
      end

      def key_id
        InboxDelivery.logger.info "#{self.class}##{__method__}"
        @linzer_signature.parameters['keyid']
      end

      def missing_signature_parameters
        InboxDelivery.logger.info "#{self.class}##{__method__}"
        REQUIRED_PARAMETERS if REQUIRED_PARAMETERS.any? { |p| @linzer_signature.parameters[p].blank? }
      end

      def signed_headers
        @signed_headers ||= @linzer_signature.components.reject { |c| c.start_with?('@') }
      end

      def verify_signature_strength!
        raise Serge::SignatureVerificationError, 'created parameter must be signed' if @linzer_signature.parameters['created'].blank?
        raise Serge::SignatureVerificationError, 'the @method and @target-uri derived components must be signed' unless @linzer_signature.components.include?('@method') && @linzer_signature.components.include?('@target-uri')
        raise Serge::SignatureVerificationError, 'the Content-Digest header must be signed when doing a POST request' if @request.post? && !signed_headers.include?('content-digest')
      end

      def verify_body_digest!
        InboxDelivery.logger.info "#{self.class}##{__method__}"
        return unless signed_headers.include?('content-digest')
        raise Serge::SignatureVerificationError, 'Content-Digest header missing' unless @request.headers.key?('content-digest')

        digests = Starry.parse_dictionary(@request.headers['content-digest'])
        raise Serge::SignatureVerificationError, "Mastodon only supports SHA-256 in Content-Digest header. Offered algorithms: #{digests.keys.join(', ')}" unless digests.key?('sha-256')

        received_digest = Base64.strict_encode64(digests['sha-256'].value)
        return if body_digest == received_digest

        raise Serge::SignatureVerificationError, "Invalid Digest value. Computed SHA-256 digest: #{body_digest}; given: #{received_digest}"
      end

      def verified?(public_key)
        InboxDelivery.logger.info "#{self.class}##{__method__}"
        key = Linzer.new_rsa_v1_5_sha256_public_key(public_key)

        Linzer.verify!(Rack::Request.new(@request.env), key:)
      rescue Linzer::VerifyError
        false
      end

      private

      def body_digest
        @body_digest ||= Digest::SHA256.base64digest(request_body)
      end

      def request_body
        @request_body ||= @request.raw_post
      end
    end
  end
end
