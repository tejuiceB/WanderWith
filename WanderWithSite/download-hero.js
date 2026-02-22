const fs = require('fs');
const https = require('https');
const path = require('path');

// Image: Friends laughing/hanging out, warm, golden hour vibe.
// https://unsplash.com/photos/group-of-friends-hanging-out-qC9N4F_5WlE 
// (Redirects to photo-1529156069898)
const url = "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=2532&auto=format&fit=crop";
const dest = path.join(__dirname, 'public', 'assets', 'hero-bg.jpg');

const file = fs.createWriteStream(dest);

const request = https.get(url, {
    headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
}, (response) => {
    if (response.statusCode !== 200) {
        console.error(`Failed to download image: StatusCode ${response.statusCode}`);
        response.resume();
        return;
    }

    response.pipe(file);

    file.on('finish', () => {
        file.close();
        console.log('New Hero Image Downloaded Successfully.');
    });
}).on('error', (err) => {
    fs.unlink(dest, () => { });
    console.error('Error downloading image:', err.message);
});
