require 'sinatra/base'

module MarkrHelpers

    def extractXMLData(raw_data)
        if raw_data.nil? || raw_data == ""
            ""
        else
            student_numbers = @data.xpath("//student-number")
            test_id = @data.xpath("//test-id")

            logger.info @data.at_css("test-id").content
            logger.info student_numbers[0].to_s
    end