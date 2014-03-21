=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'with_auditor/output'

module Arachni
module Element::Capabilities

module WithAuditor
    include Output

    # Sets the auditor for this element.
    #
    # The auditor provides its output, HTTP and issue logging interfaces.
    #
    # @return   [Arachni::Check::Auditor]
    attr_accessor :auditor

    # Removes the {#auditor} from this element.
    def remove_auditor
        self.auditor = nil
    end

    # Removes the associated {#auditor}.
    def prepare_for_report
        super if defined? super
        remove_auditor
    end

    # @return   [Bool]  `true` if it has no auditor, `false` otherwise.
    def orphan?
        !auditor
    end

    def dup
        copy_with_auditor( super )
    end

    def marshal_dump
        super.tap { |h| h.delete :@auditor }
    end

    private

    def copy_with_auditor( other )
        other.auditor = self.auditor
        other
    end

end

end
end
