const fs = require('fs')
const path = require('path')
const parse = require('csv-parse')

const input = fs.readFileSync(path.join(__dirname, 'wordList.csv'), 'utf8')

const csvToJSON = (csvData) => csvData.map((line) => {
  if (line[1] === 'alt') {
    const [head, , principle] = line

    return { head, principle }
  } else {
    const [head, tpPOS, enPOS, ...translations] = line

    return { head, tpPOS, enPOS, translations}
  }
}).reduce((hash, { head, principle, tpPOS, enPOS, translations }) => {
  if (principle) { // alternate word
    return Object.assign({}, hash, { [head]: { principle } })
  }

  const existingEntryData = hash[head] || {}
  const existingTranslations = existingEntryData[tpPOS] || []

  const newTranslations = translations.map((text) => ({ text, pos: enPOS }))

  return Object.assign({}, hash, {
    [head]: Object.assign({}, existingEntryData, {
      [tpPOS]: [...existingTranslations, ...newTranslations]
    }),
  })
}, {})

module.exports = new Promise((resolve, reject) => {
  parse(input, {relax_column_count: true}, function(err, output) {
    err ? reject(err) : resolve(csvToJSON(output))
  })
})
