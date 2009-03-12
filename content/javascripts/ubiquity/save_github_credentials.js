
CmdUtils.CreateCommand({
name: "github-auth",
icon: "http://gist.github.com/favicon.ico",
author: {name: "Mike Green", email: "mike.is.green@gmail.com", url: "http://mikedamage.github.com"},
description: "Saves your Github login and API token in Firefox's keychain. Needed to create new Gists via Ubiquity.",
takes: {"username api-token": noun_arb_text},
preview: function(pblock) { pblock.innerHTML = this.description; },
execute: function(userToken) {
  var data = userToken.text.split(' ');
  var user = data[0];
  var token = data[1];
  CmdUtils.savePassword({
   name: user,
   password: token
  });
  displayMessage("Github credentials for " + user + " saved.");
}
});
