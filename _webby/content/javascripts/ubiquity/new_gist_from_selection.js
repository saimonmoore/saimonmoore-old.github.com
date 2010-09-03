
// Create a new Github Gist from selection
CmdUtils.CreateCommand({
name: "gist",
icon: "http://gist.github.com/favicon.ico",
author: {name: "Mike Green", email: "mike.is.green@gmail.com", url: "http://mikedamage.github.com"},
description: "Creates a new Github Gist from the currently selected text. IMPORTANT: You must give Firefox your Github API token by running github-auth before using this command.",
takes: {"username": noun_arb_text},
preview: function(pblock, user) {
  var template = "<b>New gist by ${user}:</b><p><code>${gist}</code></p>";
  var selection = CmdUtils.getSelection();
  pblock.innerHTML = CmdUtils.renderTemplate(template, {user: user.text, gist: selection});
},
execute: function(user) {
  var url = "http://gist.github.com/api/v1/json/new";
  var auth = CmdUtils.retrieveLogins(user.text);
  var selection = CmdUtils.getSelection();
  var data = { login: auth.username, token: auth.password, 'files[gist.txt]': selection };
  jQuery.post(url, data, function(json) {
   var urlTemplate = "http://gist.github.com/${repo}";
   var repo = json.gists[0].repo;
   var repoURL = CmdUtils.renderTemplate(urlTemplate, {repo: repo});
   CmdUtils.copyToClipboard(repoURL);
   displayMessage("Successfully created new gist at " + repoURL);
  }, "json");
}
});