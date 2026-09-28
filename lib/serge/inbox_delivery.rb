require "logger"
require "serge/inbox_delivery/http_legacy_signature"
require "serge/inbox_delivery/http_message_signature"

module Serge
  class InboxDelivery
    EXPIRATION_WINDOW_LIMIT = 12.hours
    CLOCK_SKEW_MARGIN = 1.hour

    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new(IO::NULL)
      end
    end

    attr_reader :signature

    delegate :key_id, to: :signature

    def initialize(request)
      if request.headers['signature-input'].present?
        InboxDelivery.logger.info "#{self.class}##{__method__} signature-input: #{request.headers['signature-input']}"
        @signature = HttpMessageSignature.new(request)
      else
        InboxDelivery.logger.info "#{self.class}##{__method__} signature-input not present"
        @signature = HttpLegacySignature.new(request)
      end
    end

    def verified?(public_key)
      missing_signature_parameters = @signature.missing_signature_parameters
      raise Serge::SignatureVerificationError, "Incompatible request signature." if missing_signature_parameters
      raise Serge::SignatureVerificationError, 'Signed request date outside acceptable time window' unless matches_time_window?

      @signature.verify_signature_strength!
      @signature.verify_body_digest!
      @signature.verified?(public_key)
    end

    private

    def matches_time_window?
      created_time = @signature.created_time
      expires_time = @signature.expires_time

      if created_time.nil?
        InboxDelivery.logger.info "#{self.class}##{__method__} created_time is nil"
        return false
      end

      expires_time ||= created_time + 5.minutes
      expires_time = [expires_time, created_time + EXPIRATION_WINDOW_LIMIT].min

      return false if created_time.present? && created_time > Time.now.utc + CLOCK_SKEW_MARGIN
      return false if expires_time.present? && Time.now.utc > expires_time + CLOCK_SKEW_MARGIN

      true
    end
  end
end
