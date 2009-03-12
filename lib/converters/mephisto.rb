# Quickly hacked together my Michael Ivey
# Based on mt.rb by Nick Gerakines, open source and publically
# available under the MIT license. Use this module at your own risk.

require 'haml/html'
require 'sequel'
require 'fastercsv'
require 'fileutils'
# require File.join(File.dirname(__FILE__),"csv.rb")

# NOTE: This converter requires Sequel and the MySQL gems.
# The MySQL gem can be difficult to install on OS X. Once you have MySQL
# installed, running the following commands should work:
# $ sudo gem install sequel
# $ sudo gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
 
module Webby
  module Converters
    module Mephisto
      # This query will pull blog posts from all entries across all blogs. If
      # you've got unpublished, deleted or otherwise hidden posts please sift
      # through the created posts to make sure nothing is accidently published.      
      # QUERY = "SELECT id, permalink, body, published_at, title FROM contents WHERE user_id = 1 AND type = 'Article' AND published_at IS NOT NULL ORDER BY published_at"

      # This query will pull blog posts entries across blogs with id 1.
      QUERY = "SELECT id, permalink, body, body_html, published_at, title FROM contents WHERE site_id = 1 AND user_id = 1 AND type = 'Article' AND published_at IS NOT NULL ORDER BY published_at"

      def self.process(db, dbname, user, pass, host = 'localhost', port = nil, convert=false)
        host ||= 'localhost'
        db = case db.to_s
              when 'mysql'
                port ||= 3306
                Sequel.mysql(dbname, :user => user, :password => pass, :host => host, :port => port)
              when 'postgresql'
                port ||= 5432
                Sequel.connect("postgres://#{user}:#{pass}@#{host}:#{port}/#{dbname}")
             end
        FileUtils.mkdir_p "content"

        db[QUERY].each do |post|
          title = post[:title]
          slug = post[:permalink]
          date = post[:published_at]
          content = post[:body_html]
          name = slug + convert ? ".haml" : '.erb'
          dir = "content/tumblog/#{date.year}#{date.month}"
          FileUtils.mkdir_p dir

          data = {
             'layout' => 'tumblog/post',
             'created_at' => date,
             'author' => 'Saimon Moore',
             'filter' => convert ? 'haml' : 'erb',
             'title' => title.to_s,
             'tumblog_type' => 'regular'
           }.delete_if { |k,v| v.nil? || v == ''}.to_yaml

           converted_content = nil
          begin
            converted_content = convert ? Haml::HTML.new(content, {}).render : content
          rescue Exception => err
            puts "Unable to convert '#{dir}/#{name}' to haml..."            
            puts "err: #{err.message} trace: #{err.backtrace.join("\n")}"
            exit
            converted_content = content
          end
          File.open("#{dir}/#{name}", "w") do |f|
            f.puts data
            f.puts "---"
            f.puts converted_content
          end
        end
      end  
    end
  end
end
