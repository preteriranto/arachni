=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element
class Body < Base
    include Capabilities::WithAuditor

    def initialize( page )
        super url: page.url
        @initialized_options = page
    end

    def action
        url
    end

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

    # Matches an array of regular expressions against a string and logs the
    # result as an issue.
    #
    # @param    [Array<Regexp>]     patterns
    #   Array of regular expressions to be tested.
    # @param    [Block] block
    #   Block to verify matches before logging, must return `true`/`false`.
    def match_and_log( patterns, &block )
        elements = auditor.class.info[:elements]
        elements = auditor.class::OPTIONS[:elements] if !elements || elements.empty?

        return if !elements.include?( Body )

        [patterns].flatten.each do |pattern|
            auditor.page.body.scan( pattern ).flatten.uniq.compact.each do |proof|
                next if block_given? && !block.call( proof )

                auditor.log(
                    signature: pattern,
                    proof:     proof,
                    vector:    self
                )
            end
        end
    end

end
end
