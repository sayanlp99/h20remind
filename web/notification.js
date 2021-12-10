function askNotificationPermission() {
    function handlePermission(permission) {
        if(!('permission' in Notification)) {
        Notification.permission = permission;
        }
        if(Notification.permission === 'denied' || Notification.permission === 'default') {
        notificationBtn.style.display = 'block';
        } else {
        notificationBtn.style.display = 'none';
        }
    }
    if (!"Notification" in window) {
        console.log("This browser does not support notifications.");
    } else {
        if(checkNotificationPromise()) {
        Notification.requestPermission()
        .then((permission) => {
            handlePermission(permission);
        })
        } else {
        Notification.requestPermission(function(permission) {
            handlePermission(permission);
        });
        }
    }
}

function checkNotificationPromise() {
    try {
        Notification.requestPermission().then();
    } catch(e) {
        return false;
    }

    return true;
}

function createNotification() {
    let img = '/icons/Icon-192.png';
    let text = 'HEY! Drink some water';
    let notification = new Notification('h20remind', { body: text, icon: img });
}

askNotificationPermission();
setTimeout(createNotification, 30000);
setInterval(createNotification, 2700000);