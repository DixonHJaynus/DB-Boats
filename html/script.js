window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'showCertificate':
            showCertificate(data.data);
            break;
        case 'hideCertificate':
            hideCertificate();
            break;
    }
});

function showCertificate(certData) {
    const container = document.getElementById('certificate-container');
    
    document.getElementById('cert-title').textContent = certData.title || 'Certificate of Boat Ownership';
    document.getElementById('cert-subtitle').textContent = certData.subtitle || 'Official Maritime Registration';
    document.getElementById('cert-owner').textContent = certData.ownerName || 'Unknown';
    document.getElementById('cert-registration').textContent = certData.registration || 'N/A';
    document.getElementById('cert-vessel').textContent = certData.boatLabel || 'Unknown Vessel';
    document.getElementById('cert-location').textContent = certData.purchaseLocation || 'Unknown';
    document.getElementById('cert-date').textContent = formatDate(certData.purchaseDate);

    if (certData.upgrades) {
        setUpgradeBar('speed', certData.upgrades.speed);
        setUpgradeBar('durability', certData.upgrades.durability);
        setUpgradeBar('fuel', certData.upgrades.fuelEfficiency);
    }

    container.classList.remove('hidden');
}

function setUpgradeBar(type, data) {
    const bar = document.getElementById('upgrade-' + type + '-bar');
    const text = document.getElementById('upgrade-' + type + '-text');

    if (!data) {
        if (bar) bar.style.width = '0%';
        if (text) text.textContent = '0/5';
        return;
    }

    const level = data.level || 0;
    const maxLevel = data.maxLevel || 5;
    const percentage = (level / maxLevel) * 100;

    if (bar) {
        bar.style.width = percentage + '%';
        
        if (level === 0) {
            bar.style.background = 'rgba(139, 115, 85, 0.3)';
        } else if (level <= 2) {
            bar.style.background = 'linear-gradient(90deg, #8B7355, #a08060)';
        } else if (level <= 4) {
            bar.style.background = 'linear-gradient(90deg, #8B7355, #c9a84c)';
        } else {
            bar.style.background = 'linear-gradient(90deg, #c9a84c, #ffd700)';
        }
    }

    if (text) {
        text.textContent = level + '/' + maxLevel;
    }
}

function formatDate(dateStr) {
    if (!dateStr || dateStr === 'Unknown') return 'Unknown';
    
    try {
        const date = new Date(dateStr);
        if (isNaN(date.getTime())) return dateStr;
        
        const options = { year: 'numeric', month: 'long', day: 'numeric' };
        return date.toLocaleDateString('en-US', options);
    } catch (e) {
        return dateStr;
    }
}

function hideCertificate() {
    document.getElementById('certificate-container').classList.add('hidden');
}

function closeCertificate() {
    hideCertificate();
    
    fetch('https://DB-Boats/closeCertificate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    });
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const container = document.getElementById('certificate-container');
        if (!container.classList.contains('hidden')) {
            closeCertificate();
        }
    }
});
