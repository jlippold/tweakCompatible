function checkAction() {

    var hash = window.location.hash;
    var packageId, action, userInfo, base64;
    if (hash) {
        hash = hash.substring(3);
        var parts = hash.split("/");
        if (parts.length == 3) {
            packageId = parts[0];
            action = parts[1];
            userInfo;
            try {
                base64 = parts[2];
                userInfo = JSON.parse(atob(base64));
            } catch (err) {
                userInfo = null;
            }
        }
    }

    if (packageId && action) {
        userDetails = {
            packageId: packageId,
            action: action,
            userInfo: userInfo,
            base64: base64
        };
    }
}

function iOSVersion() {
    if (window.MSStream) {
        // There is some iOS in Windows Phone...
        // https://msdn.microsoft.com/en-us/library/hh869301(v=vs.85).aspx
        return false;
    }
    var match = (navigator.appVersion).match(/OS (\d+)_(\d+)_?(\d+)?/),
        version;

    if (match !== undefined && match !== null) {
        version = [
            parseInt(match[1], 10),
            parseInt(match[2], 10)
        ];
        if (parseInt(match[3])) {
            version.push(parseInt(match[3], 10));
        }

        var final = version.join('.');
        if (final == "11.3") {
            final = "11.3.1"; //because apple doesnt send 11.3.1 user agent :-(
        }
        return final;
    }

    return false;
}