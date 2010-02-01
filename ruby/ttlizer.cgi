#!/usr/bin/env ruby

require 'cgi'
require 'pp'
require '/home/pox/github/ttlizer/ruby/timetable.rb'

$r = CGI.new
puts $r.header 'type' => 'text/html'

class Array
    def html_table()
        raise "Should be array of arrays" unless all? {|i| i.is_a? Array}

        '<table>' + self.map{ |r|
            '<tr>' +  r.map{ |c|
                '<td>' + c + '</td>'
            }.join("\n") + '</tr>'
        }.join("\n") + '</table>'
    end
end

def start_html(title)
    return <<END_HTML
<html>
    <head>
        <title>#{title}</title>
        <link rel="stylesheet" type="text/css" href="/generic.css" />
    </head>
    <body>
END_HTML
end

def main
    File.exist? $r['url'] or
        raise "#{$r['url']} does not exist!"

    data = load_activities_from_simple_yaml File.read $r['url']

    puts start_html "ttlizer CGI test"
    puts '<h1>Best Calendar</h1>'

    puts generate_timetables(data).min_by{|t| [
        -t.days_off, # First priority
        2*t.hours_required + 5 * t.clashes
    ]}.html_calendar(0.5)

    puts <<END_HTML
        </body>
    </html>
END_HTML
end


begin
    main
rescue
    puts $!
end

