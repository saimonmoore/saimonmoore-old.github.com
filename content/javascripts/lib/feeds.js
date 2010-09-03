
function format_date(d){
  return Date.parse(d).timeDiffInWords();
}

function get_json_data(uri, options){
  var opts = options;
  new Request.JSONP({url: uri,
    onComplete: function(data){
      var list = new Element("ul");
      var item = null;
      for (var i=0; i<options.max; i++){
        switch(options.element){
          case "#twitter":
            item = twitter_entry(data[i]);
          break;
          case "#github":
            item = github_entry(data.commits[i], options.repo);
          break;
          default: break;
        }
        item.inject(list);
      }
      list.inject($$(options.element)[0]).fade('in');
    }}).send();
}

function twitter_entry(tweet){
  var it = new Element("li", {'class':'feed-item'});
  var content = tweet.text.replace(/^excsm:/, '').replace(/((http|ftp|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:\/~\+#]*[\w\-\@?^=%&amp;\/~\+#])?)/g, '<a href="$1">$1</a>').replace(/@([a-zA-Z0-9_-]*)/g, '<a href="http://www.twitter.com/$1">@$1</a>').replace(/#([a-zA-Z0-9_-]*)/g, '<a href="http://www.twitter.com/search?q=%23$1">#$1</a>');
  var dt = new Element("span", {'class': 'feed-item-date', html: format_date(tweet.created_at)+":"});
  var tx = new Element("span",{'class': 'feed-item-text', html: "&#0187;" + content});
  dt.inject(it);
  tx.inject(it);
  return it;
}

function github_entry(commit, repo){
  var it = new Element("li", {'class':'commit-data'});
  var dt = new Element("span", {'class': 'commit-date', html: format_date(commit.committed_date)+" &middot; "});
  var link = new Element("span", {'class': 'commit-link'}).adopt(new Element('a', {'href': commit.url, text: "View"}));
  var tx = new Element("span", {'class': 'commit-text', html: "[" + repo + "] " + commit.message.replace(/(closes) #(\d+)/ig, "$1 <a href='http://github.com/saimonmoore/"+repo+"/issues/#issue/$2'>#$2</a>")+"<br />"});
  tx.inject(it);
  dt.inject(it);
  link.inject(it);
  return it;
}


// http://twitter.com/status/user_timeline/excsm.json
function display_tweets(max){
  get_json_data("http://twitter.com/status/user_timeline/excsm.json", {max: max, element: '#twitter'});
}

/*
http://github.com/api/v2/json/commits/list/saimonmoore/nodered/master
*/
function display_commits(max, repos)
{
  for (var i=0; i<repos.length; i++){
    get_json_data(repos[i].uri, {max: max, element: '#github', repo: repos[i].repo});
  }
}
