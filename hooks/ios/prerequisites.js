console.error("Google Sign-In prerequisites");

module.exports = function (context) {
  var child_process = require('child_process');

  var Q;
  try {
    Q = require('q');
  } catch (e) {
    Q = context.requireCordovaModule('q');
  }

  var deferral = Q.defer();

  var output = child_process.exec('npm install', {cwd: __dirname},
      function (error) {
        if (error !== null) {
          console.log('exec error: ' + error);
          deferral.reject('npm installation failed');
        }
        deferral.resolve();
      });

  return deferral.promise;
};
