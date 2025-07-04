# frozen_string_literal: true

module LogBench
  # Validates that lograge is properly configured for LogBench
  class ConfigurationValidator
    class ConfigurationError < StandardError; end
    ERROR_CONFIGS = {
      enabled: {
        title: "Lograge is not enabled",
        description: "LogBench requires lograge to be enabled in your Rails application.",
        fix: "config.lograge.enabled = true"
      },
      options: {
        title: "Lograge custom_options missing",
        description: "LogBench needs custom_options to include params fields.",
        fix: <<~FIX.strip
          config.lograge.custom_options = lambda do |event|
            params = event.payload[:params]&.except("controller", "action")
            { params: params } if params.present?
          end
        FIX
      },
      lograge_formatter: {
        title: "Wrong lograge formatter",
        description: "LogBench requires Lograge::Formatters::Json for lograge formatting.",
        fix: "config.lograge.formatter = Lograge::Formatters::Json.new"
      },
      logger_formatter: {
        title: "Wrong Rails logger formatter",
        description: "LogBench requires LogBench::JsonFormatter for Rails logger formatting.",
        fix: "config.logger.formatter = LogBench::JsonFormatter.new"
      }
    }.freeze

    def self.validate_rails_config!
      new.validate_rails_config!
    end

    def validate_rails_config!
      return true unless defined?(Rails) && Rails.application

      validate_lograge_enabled!
      validate_custom_options!
      validate_lograge_formatter!
      validate_logger_formatter!

      true
    end

    private

    def validate_lograge_enabled!
      unless lograge_config&.enabled
        raise ConfigurationError, build_error_message(:enabled)
      end
    end

    def validate_custom_options!
      unless lograge_config&.custom_options
        raise ConfigurationError, build_error_message(:options)
      end
    end

    def validate_lograge_formatter!
      formatter = lograge_config&.formatter
      unless formatter.is_a?(Lograge::Formatters::Json)
        raise ConfigurationError, build_error_message(:lograge_formatter)
      end
    end

    def validate_logger_formatter!
      logger = Rails.application.config.logger
      formatter = logger&.formatter
      unless formatter.is_a?(LogBench::JsonFormatter)
        raise ConfigurationError, build_error_message(:logger_formatter)
      end
    end

    def lograge_config
      return nil unless Rails.application.config.respond_to?(:lograge)
      Rails.application.config.lograge
    end

    def build_error_message(error_type)
      config = ERROR_CONFIGS[error_type]

      <<~ERROR
        ❌ #{config[:title]}

        #{config[:description]}

        Add this to config/environments/development.rb:
        #{config[:fix]}

        For complete setup: https://github.com/silva96/log_bench#configuration
      ERROR
    end
  end
end
