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
var CLIENT_ID = '';
var REVERSED_CLIENT_ID = '';

if(process.argv.join("|").indexOf("REVERSED_CLIENT_ID=") > -1) {
    REVERSED_CLIENT_ID = process.argv.join("|").match(/REVERSED_CLIENT_ID=(.*?)(\||$)/)[1]
} else {
    var config = fs.readFileSync("config.xml").toString();
    REVERSED_CLIENT_ID = getPreferenceValue(config, "REVERSED_CLIENT_ID");
}

if (REVERSED_CLIENT_ID !== '') {
    CLIENT_ID = REVERSED_CLIENT_ID.split('.').reverse().join('.');
}

var files = [
    "platforms/browser/www/plugins/cordova-plugin-googleplus/src/browser/GooglePlusProxy.js",
    "platforms/browser/platform_www/plugins/cordova-plugin-googleplus/src/browser/GooglePlusProxy.js"
];

for(var i=0; i<files.length; i++) {
    try {
        var contents = fs.readFileSync(files[i]).toString();
        fs.writeFileSync(files[i], contents.replace(/CLIENT_ID/g, '"' + CLIENT_ID + '"'));
    } catch(err) {}
}
