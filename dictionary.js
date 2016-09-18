const fs = require('fs')
const path = require('path')
const parse = require('csv-parse')

const input = fs.readFileSync(path.join(__dirname, 'wordList.csv'), 'utf8')

const csvToJSON = (csvData) => csvData.map((line) => {
  if (line[1] === 'alt') {
    const [head, _, principle] = line

    return {
      [head]: principle
    }
  } else {
    const [head, syntax, semantics, ...translations] = line

    return {
      [head]: { [syntax]: translations },
    }
  }
}).reduce((hash, entry) => {
  const [head] = Object.keys(entry)

  if (typeof entry[head] === 'string') { // alternate word
    return Object.assign({}, hash, entry)
  }

  const [syntax] = Object.keys(entry[head])
  const existingEntryData = hash[head] || {}
  const existingTranslations = existingEntryData[syntax] || []

  return Object.assign({}, hash, {
    [head]: Object.assign({}, existingEntryData, {
      [syntax]: [...existingTranslations, ...entry[head][syntax]]
    }),
  })
}, {})

module.exports = new Promise((resolve, reject) => {
  parse(input, {relax_column_count: true}, function(err, output) {
    err ? reject(err) : resolve(csvToJSON(output))
  })
})
