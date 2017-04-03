var fs = require('fs');

const dic = require('./dictionary').then((data) => {
  const text = `export default ${JSON.stringify(data, null, ' '.repeat(3))}`

  fs.writeFile('./dictionaryEntries.js', text, function(err) {
    if(err) {
      return console.log(err)
    }

    console.log("The file was saved!")
  })
})
