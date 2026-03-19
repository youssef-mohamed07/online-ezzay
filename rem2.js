const fs = require('fs');
const path = require('path');

function removeDeepConst(content) {
    // This script finds multiline `const Text(` or `const Padding(` etc that wrap `.tr`
    const regexps = [
        /const\s+(EdgeInsets|Text|Padding|Center|Column|Row|SizedBox|Align)\b/g,
        /const\s+(\w+)\(/g,
        /const\s+\[/g
    ];
    let newContent = content;
    // We just remove 'const' if the file has '.tr'
    if (newContent.includes('.tr')) {
        for(let r of regexps) {
           newContent = newContent.replace(r, match => match.replace('const ', ''));
        }
    }
    return newContent;
}

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(file));
        } else if (file.endsWith('.dart')) {
            results.push(file);
        }
    });
    return results;
}

const files = walk('lib/views');
files.forEach(f => {
    let c = fs.readFileSync(f, 'utf8');
    let nc = removeDeepConst(c);
    if(c !== nc) {
        fs.writeFileSync(f, nc, 'utf8');
        console.log("Updated", f);
    }
});
