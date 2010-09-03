Loquacious.configuration_for(:webby) {
  desc "The default directory where new tumblog posts will be created."
  tumblog_dir 'tumblog'
}

namespace :tumblog do
  namespace :converters do

    desc "Convert mysql mephisto posts into tumblog posts"
    task :mysql_mephisto do |t|
      Webby::Converters::Mephisto.process(:mysql, ENV['DBNAME'], ENV['DBUSER'], ENV['DBPASS'], ENV['DBHOST'], ENV['DBPORT'])
    end

    desc "Convert postgresql mephisto posts into tumblog posts"
    task :pg_mephisto do |t|
      Webby::Converters::Mephisto.process(:postgresql, ENV['DBNAME'], ENV['DBUSER'], ENV['DBPASS'], ENV['DBHOST'], ENV['DBPORT'])
    end

    desc "Import mysql mephisto comments into disqus"
    task :mysql_mephisto_comments do |t|
      Webby::Converters::Mephisto.process(ENV['DISQUS_ACCOUNT'], ENV['DISQUS_API_KEY'], :mysql, ENV['DBNAME'], ENV['DBUSER'], ENV['DBPASS'], ENV['DBHOST'], ENV['DBPORT'])
    end

    desc "Import postgresql mephisto comments into disqus"
    task :pg_mephisto_comments do |t|
      Webby::Converters::Mephisto.comments(ENV['DISQUS_ACCOUNT'], ENV['DISQUS_API_KEY'], :postgresql, ENV['DBNAME'], ENV['DBUSER'], ENV['DBPASS'], ENV['DBHOST'], ENV['DBPORT'])
    end
  end

 # iterate over all the files in the "templates/tumblog" folder and create a
  # rake task corresponding to each file found
  FileList["#{Webby.site.template_dir}/tumblog/*"].each do |template|
    next unless test(?f, template)
    name = template.pathmap('%n')

    desc "Create a new tumblog #{name}"
    task name do |t|
      page  = Webby.site.args.page
      title = Webby.site.args.title
      dir   = Webby.site.args.dir

      # if no directory was given use the default tumblog directory (underneath
      # the content directory)
      dir = Webby.site.tumblog_dir if dir.empty?
      dir = File.join(dir, Time.now.strftime('%Y%m'))

      page = File.join(dir, File.basename(page))
      page = Webby::Builder.create(page, :from => template,
                 :locals => {:title => title, :directory => dir})
      Webby.exec_editor(page)
    end
  end  # each

end  # namespace :tumblog

# EOF
