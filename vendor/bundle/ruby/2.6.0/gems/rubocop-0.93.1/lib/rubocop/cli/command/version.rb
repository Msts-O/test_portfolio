# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Display version.
      # @api private
      class Version < Base
        self.command_name = :version

        def run
          puts RuboCop::Version.version(debug: false) if @options[:version]
          puts RuboCop::Version.version(debug: true) if @options[:verbose_version]
        end
      end
    end
  end
end
