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
      COMMENTS_QUERY = "SELECT id, article_id, title, permalink, body, body_html, published_at, author, author_url, author_email, author_ip FROM contents WHERE site_id = 1 AND type = 'Comment' AND published_at IS NOT NULL ORDER BY published_at DESC"

      def self.comments(disqus_account, disqus_api_key, db, dbname, user, pass, host = 'localhost', port = nil, convert=false)
        require 'disqus'
        require 'disqus/api'
        require 'disqus/forum'
        require 'disqus/thread'
        require 'disqus/post'
                
        Disqus::defaults[:account] = disqus_account
        Disqus::defaults[:api_key] = disqus_api_key
        
        # Assume only one blog
        forum = Disqus::Forum.list.first
        raise "Need at least one disqus forum to import comments into..." unless forum
        
        host ||= 'localhost'
        db = case db.to_s
              when 'mysql'
                port ||= 3306
                Sequel.mysql(dbname, :user => user, :password => pass, :host => host, :port => port)
              when 'postgresql'
                port ||= 5432
                Sequel.connect("postgres://#{user}:#{pass}@#{host}:#{port}/#{dbname}")
             end

        db[COMMENTS_QUERY].each do |comment|
          comment_id = comment[:id]
          article_id = comment[:article_id]
          title = comment[:title]
          slug = comment[:permalink]
          author_name = comment[:author_name]
          author_url = comment[:author_url]
          author_email = comment[:author_email]
          author_ip = comment[:author_ip]
          date = comment[:published_at]
          content = comment[:body_html]
          dir = "#{date.year}#{date.month}"
          
          article_url = "http://saimonmoore.net/tumblog/" + slug + '.html'
          r = Disqus::Api.get_thread_by_url(:forum_api_key => forum.key, :url => article_url)
          # {"message"=>{"slug"=>"thread", "forum"=>"98781", "num_comments"=>0, "title"=>"http://localhost:4331/tumblog/20081/created-mongrel-dont-serve-static-patch-ticket.html", "url"=>"http://localhost:4331/tumblog/20081/created-mongrel-dont-serve-static-patch-ticket.html", "id"=>"13518564", "forum_obj"=>{"name"=>"Simple Thoughts", "shortname"=>"saimonmoorenet", "id"=>"98781", "created_at"=>"2009-03-12 06:33:27.380739"}, "identifier"=>nil, "hidden"=>true, "created_at"=>"2009-03-12T10:42", "allow_comments"=>true}, "succeeded"=>true, "code"=>"ok"}
          
          unless r['succeeded']
            # create a new thread for the post
            r = Disqus::Api.thread_by_identifier(:forum_api_key => forum.key, :title => article_url, :identifier => nil)
          end
          
          if r['succeeded']
            thread = r['message']
            raise "Unable to find/create thread for article: #{slug}" unless thread && thread['id']
            r = Disqus::Api.create_post(:forum_api_key => forum.key, :thread_id => thread['id'], :message => content, :author_name => author_name, :author_email => author_email, :ip_address => author_ip, :parent_post => article_id.to_s, :created_at => comment.published_at.strftime('%Y-%m-%dT%H:%M'))
            if r['succeeded']
              puts "created disqus comment for: #{slug}"
            else
              puts "failed to create comment for: #{slug} Reason: #{r['code']} Comment: #{comment.inspect}"
            end
          end
        end

      end

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
          entry_id = post[:id]
          title = post[:title]
          slug = post[:permalink]
          date = post[:published_at]
          content = post[:body_html]
          name = slug + (convert ? ".haml" : '.erb')
          dir = "content/tumblog/#{date.year}#{date.month}"
          FileUtils.mkdir_p dir

          data = {
             'layout' => 'tumblog/post',
             'created_at' => date,
             'author' => 'Saimon Moore',
             'filter' => (convert ? 'haml' : 'erb'),
             'title' => title.to_s,
             'tumblog_type' => 'regular',
             'entry_id' => entry_id,
           }.delete_if { |k,v| v.nil? || v == ''}.to_yaml

           converted_content = nil
          begin
            converted_content = (convert ? Haml::HTML.new(content, {}).render : content)
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
