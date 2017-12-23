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
