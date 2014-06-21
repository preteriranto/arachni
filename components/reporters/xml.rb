=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'nokogiri'
require 'base64'

# Creates an XML report of the audit.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.5
class Arachni::Reporters::XML < Arachni::Reporter::Base
    load Arachni::Options.paths.reporters + '/xml/buffer.rb'

    include Buffer

    SCHEMA = File.dirname( __FILE__ ) + '/xml/schema.xsd'

    def run
        # get XML formatted plugin data and append them to the XML buffer
        # along with some generic info
        # format_plugin_results.each do |plugin, results|
        #     start_tag plugin
        #     simple_tag( 'name', auditstore.plugins[plugin][:name] )
        #     simple_tag( 'description', auditstore.plugins[plugin][:description] )
        #
        #     start_tag 'results'
        #     append( results )
        #     end_tag 'results'
        #
        #     end_tag plugin
        # end

        builder = Nokogiri::XML::Builder.new do |xml|
            xml.report(
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'xsi:noNamespaceSchemaLocation' => SCHEMA
            ) {
                xml.version report.version
                xml.options Arachni::Options.hash_to_save_data( report.options )
                xml.start_datetime report.start_datetime.xmlschema
                xml.finish_datetime report.finish_datetime.xmlschema

                xml.sitemap {
                    report.sitemap.each do |url, code|
                        xml.sitemapentry {
                            xml.url url
                            xml.code code
                        }
                    end
                }

                xml.issues {
                    report.issues.each do |issue|
                        xml.issue {
                            xml.name issue.name
                            xml.description issue.description
                            xml.remedy_guidance issue.remedy_guidance
                            xml.severity issue.severity
                            xml.cwe issue.cwe
                            xml.digest issue.digest

                            issue.references.each do |title, url|
                                xml.title title
                                xml.url url
                            end

                            vector = issue.vector
                            xml.vector {
                                xml.class_ vector.class
                                xml.type vector.type
                                xml.url vector.url

                                if issue.active?
                                    xml.action vector.action
                                    xml.method_ vector.method
                                    xml.affected_input_name vector.affected_input_name

                                    add_inputs( xml, vector.default_inputs )
                                end
                            }

                            issue.variations.each do |variation|
                                xml.variations {
                                    xml.variation {
                                        vector = variation.vector
                                        xml.vector {
                                            if issue.active?
                                                xml.method_ vector.method
                                                xml.affected_input_value vector.affected_input_value
                                                xml.seed vector.seed

                                                add_inputs( xml, vector.inputs )
                                            end
                                        }

                                        xml.remarks {
                                            variation.remarks.each do |commenter, remarks|
                                                xml.commenter commenter
                                                remarks.each do |remark|
                                                    xml.remark remark
                                                end
                                            end
                                        }

                                        add_page( xml, variation.page )
                                        add_page( xml, variation.referring_page, :referring_page )

                                        xml.signature variation.signature
                                        xml.proof variation.proof
                                        xml.trusted variation.trusted
                                        xml.platform_type variation.platform_type
                                        xml.platform_name variation.platform_name
                                    }
                                }
                            end
                        }
                    end
                }
            }
        end

        puts xml = builder.to_xml

        xsd = Nokogiri::XML::Schema( IO.read( SCHEMA ) )
        xsd.validate( Nokogiri::XML( xml ) ).each do |error|
            puts error.message
        end

        IO.binwrite( outfile, xml )
        print_status "Saved in '#{outfile}'."
    end

    def self.info
        {
            name:         'XML',
            description:  %q{Exports the audit results as an XML (.xml) file.},
            content_type: 'text/xml',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.2.4',
            options:      [ Options.outfile( '.xml' ), Options.skip_responses ]
        }
    end

    def add_inputs( xml, inputs, name = :inputs )
        xml.send( name ) {
            inputs.each do |k, v|
                xml.input( name: k, value: v )
            end
        }

    end

    def add_page( xml, page, name = :page )
        xml.send( name ) {
            xml.body page.body

            request = page.request
            xml.request {
                xml.url request.url
                xml.method_ request.method

                add_inputs( xml, request.parameters, :parameters )
                add_inputs( xml, request.headers, :headers )

                xml.body request.body
                xml.raw request.to_s
            }

            response = page.response
            xml.response {
                xml.url response.url
                xml.code response.code
                xml.ip_address response.ip_address
                xml.time response.time
                xml.curl_code response.return_code
                xml.curl_message response.return_message

                add_inputs( xml, response.headers, :headers )

                xml.body response.body
                xml.raw_headers response.headers_string
            }

            dom = page.dom
            xml.dom {
                xml.url dom.url

                xml.transitions {
                    dom.transitions.each do |transition|
                        xml.transition {
                            xml.element transition.element
                            xml.event transition.event
                            xml.time transition.time
                        }
                    end
                }

                xml.data_flow_sinks {
                    dom.data_flow_sink.each do |sink|
                        xml.data_flow_sink {
                            xml.object sink.object
                            xml.tainted_argument_index sink.tainted_argument_index
                            xml.tainted_value sink.tainted_value
                            xml.taint_ sink.taint

                            add_function( xml, sink.function )
                            add_trace( xml, sink.trace )
                        }
                    end
                }

                xml.execution_flow_sinks {
                    dom.execution_flow_sink.each do |sink|
                        xml.execution_flow_sink {
                            add_trace( xml, sink.trace )
                        }
                    end
                }
            }
        }
    end

    def add_trace( xml, trace )
        xml.trace {
            trace.each do |frame|
                xml.frame {
                    add_function( xml, frame.function )
                    xml.line frame.line
                    xml.url frame.url
                }
            end
        }
    end

    def add_function( xml, function )
        xml.function {
            xml.name function.name
            xml.source function.source
            xml.arguments {
                if function.arguments
                    function.arguments.each do |argument|
                        xml.argument argument.inspect
                    end
                end
            }
        }
    end

end
