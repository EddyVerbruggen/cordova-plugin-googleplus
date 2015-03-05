function GooglePlus() {
}

GooglePlus.prototype.isAvailable = function (callback) {
  cordova.exec(callback, null, "GooglePlus", "isAvailable", []);
};

GooglePlus.prototype.login = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GooglePlus", "login", [options]);
};

GooglePlus.prototype.trySilentLogin = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GooglePlus", "trySilentLogin", [options]);
};

GooglePlus.prototype.logout = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GooglePlus", "logout", []);
};

GooglePlus.prototype.disconnect = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "GooglePlus", "disconnect", []);
};

GooglePlus.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.googleplus = new GooglePlus();
  return window.plugins.googleplus;
};

cordova.addConstructor(GooglePlus.install);