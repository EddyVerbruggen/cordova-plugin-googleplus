
//import GooglePlusProxy from "../browser/GooglePlusProxy"

module.exports = function(messages){

	function _isAvailable(success, error){
		if (!window.__googleSdkReady) {
			return window.__googleCallbacks.push(function() {
				_isAvailable(success, error);
			});
		}

		success(window.gapi !== undefined);
	}

	function _updateSigninStatus (isSignedIn, success, error) {
		if (isSignedIn) {
			var auth2 = gapi.auth2.getAuthInstance();
			var user = auth2.currentUser.get();
			if (!user) {
				error({'error': 'User not found.'});
				return false;
			}

			var profile = user.getBasicProfile();
			var authResponse = user.getAuthResponse(true);
			if (success) {
				success({
					"accessToken": authResponse['access_token'],
					"expires": authResponse['expires_at'],
					"expires_in": authResponse['expires_in'],
					"idToken": authResponse['id_token'],
					"serverAuthCode": authResponse['server_auth_code'],
					"email": profile.getEmail(),
					"userId": profile.getId(),
					"displayName": profile.getName(),
					"familyName": profile.getFamilyName(),
					"givenName": profile.getGivenName(),
					"imageUrl": profile.getImageUrl()
				});
			}

		} else {
			if (error) error({'error': 'User not logged in.'});
		}
	}

	function _trySilentLogin (success, error, options) {
		if (!window.__googleSdkReady) {
			return window.__googleCallbacks.push(function() {
				_trySilentLogin(success, error, options);
			});
		}

		_updateSigninStatus(gapi.auth2.getAuthInstance().isSignedIn.get(), success, error);
	}

	function _login (success, error, options) {
		var that = this;
		if (!window.__googleSdkReady) {
			return window.__googleCallbacks.push(function() {
				that.login(success, error, options);
			});
		}
		
		gapi.auth2.getAuthInstance().signIn(options).then(function () {
			_updateSigninStatus(gapi.auth2.getAuthInstance().isSignedIn.get(), success, error);
		}, function(err) {
			error(err);
		});
	}

	function _logout(success, error) {
		const self = this
		if (!window.__googleSdkReady) {
			return window.__googleCallbacks.push(function() {
				_.logout(success, error);
			});
		}

		gapi.auth2.getAuthInstance().signOut().then(success, function(err) {
			error(err);
		});
	}

	function _disconnect(success, error) {
		if (!window.__googleSdkReady) {
			return window.__googleCallbacks.push(function() {
				_disconnect(success, error);
			});
		}

		gapi.auth2.getAuthInstance().disconnect().then(success, function(err) {
			error(err);
		});
	}

	function _getSigningCertificateFingerprint (success, error) {
		console.warn('Not implemented.');
		console.trace();
	}


	return {
		GooglePlus: {
			isAvailable: function(success, error){
				_isAvailable(success, error);
			},
			updateSigninStatus: function (isSignedIn, success, error) {
				_updateSigninStatus(isSignedIn, success, error)
			},		
			trySilentLogin: function (success, error, options) {
				_trySilentLogin(success, error, options)
			},
		
			login: function (success, error, options) {
				_login(success, error, options)
			},
		
			logout: function (success, error) {
				_logout(success, error) 
			},
		
			disconnect: function (success, error) {
				_disconnect(success, error) 
			},
		
			getSigningCertificateFingerprint: function (success, error) {
				console.warn('Not implemented.');
				console.trace();
			}
		}

	}

}
