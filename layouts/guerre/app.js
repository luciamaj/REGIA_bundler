import data from '../data.js';
console.log(data);

let images = data["data"]["tematiche"].flatMap(t => t.foto);

for (let i of images) {
    let img = document.createElement('img');
    img.setAttribute('src', `../assets/${i}`);
    document.body.append(img);
}