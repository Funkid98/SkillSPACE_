const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            if (!file.includes('node_modules')) {
                results = results.concat(walk(file));
            }
        } else {
            if (file.endsWith('.js')) {
                results.push(file);
            }
        }
    });
    return results;
}

const files = walk('Backend');
files.forEach(f => {
    let content = fs.readFileSync(f, 'utf8');
    if (content.includes('127.0.0.1:8088')) {
        content = content
            .replace(/"http:\/\/127\.0\.0\.1:8088/g, '(process.env.INTERNAL_GATEWAY_URL || "http://127.0.0.1:8088") + "')
            .replace(/`http:\/\/127\.0\.0\.1:8088/g, '`${process.env.INTERNAL_GATEWAY_URL || "http://127.0.0.1:8088"}');
        fs.writeFileSync(f, content);
        console.log('Updated ' + f);
    }
});
