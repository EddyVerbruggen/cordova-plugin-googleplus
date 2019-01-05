
module.exports = {
	initialize: function() {

		//Not the best solution attaching to window, but instanced classes don't seem to work :/
		window.__googleSdkReady = false;
		window.__googleCallbacks = [];

		if (window.location.protocol === "file:") {
			console.warn("Google API is not supported when using file:// protocol");
		} else {

			//Extract WEB_APPLICATION_CLIENT_ID from config.xml
			fetch("../config.xml")
				.then(response => response.text())
				.then(data => {
					//We have the xml data.. Parse it
					return this.getPreferenceValue(data, "WEB_APPLICATION_CLIENT_ID");
				})
				.then(clientId => {
					if(clientId !== null){
						this.initLoad(clientId);
					} else {
						console.error("Client id not found in config.xml")
					}
				})

		};
	},

	getPreferenceValue: function(config, name) {
		var value = config.match(new RegExp('name="' + name + '" value="(.*?)"', "i"));
		if(value && value[1]) {
			return value[1]
		} else {
			return null
		}
	},

	initLoad: function(clientId){
		const self = this

		window.handleClientLoad = function() {
			gapi.load('auth2', function () {
				gapi.auth2.init({
					client_id: clientId
				}).then(function () {
					window.__googleSdkReady = true;

					for (var i = 0; i < window.__googleCallbacks.length; i++) {
						window.__googleCallbacks[i].call(self);
					}

					// Listen for sign-in state changes.
					gapi.auth2.getAuthInstance().isSignedIn.listen(self.updateSigninStatus);
				}, function(error) {
					if (error.details) {
						console.error(error.details);
					} else {
						console.error(error);
					}
				});
			});
		};

		(function(d, s, id){
			var js, fjs = d.getElementsByTagName(s)[0];
			if (d.getElementById(id)) {return;}
			js = d.createElement(s); js.id = id;
			js.onload = function () { window.handleClientLoad(); };
			js.onreadystatechange = function () { if (this.readyState === 'complete') js.onload(); };
			js.src = "https://apis.google.com/js/api.js";
			fjs.parentNode.insertBefore(js, fjs);
		}(document, 'script', 'googleplus-jssdk'));
	}
	
}