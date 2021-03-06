# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # This cop checks for places where string concatenation
      # can be replaced with string interpolation.
      #
      # The cop can autocorrect simple cases but will skip autocorrecting
      # more complex cases where the resulting code would be harder to read.
      # In those cases, it might be useful to extract statements to local
      # variables or methods which you can then interpolate in a string.
      #
      # @example
      #   # bad
      #   email_with_name = user.name + ' <' + user.email + '>'
      #
      #   # good
      #   email_with_name = "#{user.name} <#{user.email}>"
      #   email_with_name = format('%s <%s>', user.name, user.email)
      #
      class StringConcatenation < Base
        include Util
        extend AutoCorrector

        MSG = 'Prefer string interpolation to string concatenation.'
        RESTRICT_ON_SEND = %i[+].freeze

        def_node_matcher :string_concatenation?, <<~PATTERN
          {
            (send str_type? :+ _)
            (send _ :+ str_type?)
          }
        PATTERN

        def on_send(node)
          return unless string_concatenation?(node)

          topmost_plus_node = find_topmost_plus_node(node)

          parts = []
          collect_parts(topmost_plus_node, parts)

          add_offense(topmost_plus_node) do |corrector|
            if parts.none? { |part| uncorrectable?(part) }
              corrector.replace(topmost_plus_node, replacement(parts))
            end
          end
        end

        private

        def find_topmost_plus_node(node)
          current = node
          while (parent = current.parent) && plus_node?(parent)
            current = parent
          end
          current
        end

        def collect_parts(node, parts)
          return unless node

          if plus_node?(node)
            collect_parts(node.receiver, parts)
            collect_parts(node.first_argument, parts)
          else
            parts << node
          end
        end

        def plus_node?(node)
          node.send_type? && node.method?(:+)
        end

        def uncorrectable?(part)
          part.multiline? ||
            part.dstr_type? ||
            (part.str_type? && part.heredoc?) ||
            part.each_descendant(:block).any?
        end

        def replacement(parts)
          interpolated_parts =
            parts.map do |part|
              if part.str_type?
                if single_quoted?(part)
                  part.value.gsub('\\') { '\\\\' }
                else
                  part.value.inspect[1..-2]
                end
              else
                "\#{#{part.source}}"
              end
            end

          "\"#{interpolated_parts.join}\""
        end

        def single_quoted?(str_node)
          str_node.source.start_with?("'")
        end
      end
    end
  end
end
