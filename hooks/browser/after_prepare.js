#!/usr/bin/env node
'use strict';

var fs = require('fs');

var getPreferenceValue = function(config, name) {
    var value = config.match(new RegExp('name="' + name + '" value="(.*?)"', "i"));
    if(value && value[1]) {
        return value[1]
    } else {
        return null
    }
};
var getPreferenceValueFromPackageJson = function (config, name) {
    var value = config.match(new RegExp('"' + name + '":\\s"(.*?)"', "i"));
    if (value && value[1]) {
        return value[1]
    } else {
        return null
    }
};

var WEB_APPLICATION_CLIENT_ID = '';

if(process.argv.join("|").indexOf("WEB_APPLICATION_CLIENT_ID=") > -1) {
    WEB_APPLICATION_CLIENT_ID = process.argv.join("|").match(/WEB_APPLICATION_CLIENT_ID=(.*?)(\||$)/)[1]
} else {
    var config = fs.readFileSync("config.xml").toString();
    WEB_APPLICATION_CLIENT_ID = getPreferenceValue(config, "WEB_APPLICATION_CLIENT_ID");
    if (!WEB_APPLICATION_CLIENT_ID) {
        var packageJson = fs.readFileSync("package.json").toString();
        WEB_APPLICATION_CLIENT_ID = getPreferenceValueFromPackageJson(packageJson, "WEB_APPLICATION_CLIENT_ID");
    }
}

var files = [
    "platforms/browser/www/plugins/cordova-plugin-googleplus/src/browser/GooglePlusProxy.js",
    "platforms/browser/platform_www/plugins/cordova-plugin-googleplus/src/browser/GooglePlusProxy.js"
];

for(var i=0; i<files.length; i++) {
    try {
        var contents = fs.readFileSync(files[i]).toString();
        fs.writeFileSync(files[i], contents.replace(/client_id: "[^"]+"/g, `client_id: "${WEB_APPLICATION_CLIENT_ID}"`));
    } catch(err) {}
}
