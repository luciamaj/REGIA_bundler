import data from '../data.js';
console.log(data);

let images = data["data"]["result"].map(t => t["foto_persone"]);

for (let i of images) {
    if (i === undefined) continue;

    let img = document.createElement('img');
    img.setAttribute('src', `../assets/${i}`);
    document.body.append(img);
}