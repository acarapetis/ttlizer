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

    count = $r['count'].to_i || 1
    count = 1 if count == 0

    data = load_activities_from_simple_yaml File.read $r['url']

    puts start_html "ttlizer CGI test"
    puts "<h1>#{count} best calendar#{ count > 1 ? 's' : '' }</h1>"

    timetables = generate_timetables(data).sort_by{|t| [
        -t.days_off, # First priority
        t.hours_required + 5 * t.clashes
    ]}
    
    timetables.take(count).each do |tt| 
        puts %Q{<p>Hours required: #{tt.hours_required}, Clashes: #{tt.clashes}</p>}
        puts tt.html_calendar(0.5)
        puts '<br />'
    end

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

