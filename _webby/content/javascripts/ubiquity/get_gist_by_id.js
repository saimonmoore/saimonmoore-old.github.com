
// Get & copy a Gist by ID
CmdUtils.CreateCommand({
	name: "gist-copy",
	icon: "http://gist.github.com/favicon.ico",
	author: {name: "Mike Green", email: "mike.is.green@gmail.com"},
	takes: {"gist": noun_arb_text},
	preview: function(pblock, theGist) {
		var urlTemplate = "http://gist.github.com/${gist}.txt";
		var gistURL = CmdUtils.renderTemplate(urlTemplate, {gist: theGist.text});
		CmdUtils.previewGet(pblock, gistURL, {}, function(data) {
			pblock.innerHTML = data;
		});
	},
	execute: function(theGist) {
		var urlTemplate = "http://gist.github.com/${gist}.txt";
		var gistURL = CmdUtils.renderTemplate(urlTemplate, {gist: theGist.text});
		jQuery.get(gistURL, {}, function(data) {
			CmdUtils.copyToClipboard(data);
			displayMessage("Gist " + theGist.text + " copied to clipboard.");
		});
	}
});