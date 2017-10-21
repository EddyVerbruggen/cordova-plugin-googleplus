console.log("START Running hook to add iOS Keychain Sharing entitlements (required since iOS 10)");

var xcode = require('xcode'),
    fs = require('fs'),
    path = require('path'),
    plist = require('plist'),
    util = require('util');

module.exports = function (context) {
  var Q = context.requireCordovaModule('q');
  var deferral = new Q.defer();

  if (context.opts.cordova.platforms.indexOf('ios') < 0) {
    throw new Error('This plugin expects the ios platform to exist.');
  }

  var iosPlatform = path.join(context.opts.projectRoot, 'platforms/ios/');
  var iosFolder = fs.existsSync(iosPlatform) ? iosPlatform : context.opts.projectRoot;

  fs.readdir(iosFolder, function (err, data) {
    if (err) {
      throw err;
    }

    var projFolder;
    var projName;

    // Find the project folder by looking for *.xcodeproj
    if (data && data.length) {
      data.forEach(function (folder) {
        if (folder.match(/\.xcodeproj$/)) {
          projFolder = path.join(iosFolder, folder);
          projName = path.basename(folder, '.xcodeproj');
        }
      });
    }

    if (!projFolder || !projName) {
      throw new Error("Could not find an .xcodeproj folder in: " + iosFolder);
    }

    var destFolder = path.join(iosFolder, projName, 'Resources');
    if (!fs.existsSync(destFolder)) {
      fs.mkdirSync(destFolder);
    }

    var destFile = path.join(destFolder, projName + '.entitlements');
    if (fs.existsSync(destFile)) {
      console.error("File exists, not doing anything: " + destFile);
      deferral.resolve();

    } else {
      console.log("Will add iOS Keychain Sharing entitlements to project '" + projName + "'");

      //var projectPlistPath = path.join(context.opts.projectRoot, 'platforms/ios', projName, util.format('%s-Info.plist', projName));
      var projectPlistPath = path.join(iosFolder, projName, util.format('%s-Info.plist', projName));
      var projectPlistJson = plist.parse(fs.readFileSync(projectPlistPath, 'utf8'));
      var bundleID = projectPlistJson.CFBundleIdentifier;

      // create a new entitlements plist file
      var sourceFile = path.join(context.opts.plugin.pluginInfo.dir, 'src/ios/resources/KeychainSharing.entitlements');
      fs.readFile(sourceFile, 'utf8', function (err, data) {
        data = data.replace(/__KEYCHAIN_ACCESS_GROUP__/g, bundleID);

        fs.writeFileSync(destFile, data);

        var projectPath = path.join(projFolder, 'project.pbxproj');

        var pbxProject;
        if (context.opts.cordova.project) {
          pbxProject = context.opts.cordova.project.parseProjectFile(context.opts.projectRoot).xcode;
        } else {
          pbxProject = xcode.project(projectPath);
          pbxProject.parseSync();
        }

        pbxProject.addResourceFile(projName + ".entitlements");

        var configGroups = pbxProject.hash.project.objects['XCBuildConfiguration'];
        for (var key in configGroups) {
          var config = configGroups[key];
          if (config.buildSettings !== undefined) {
            config.buildSettings.CODE_SIGN_ENTITLEMENTS = '"' + projName + '/Resources/' + projName + '.entitlements"';
          }
        }

        // write the updated project file
        fs.writeFileSync(projectPath, pbxProject.writeSync());
        console.log("END Running hook to add iOS Keychain Sharing entitlements (required since iOS 10)");

        deferral.resolve();
      });
    }
  });

  return deferral.promise;
};