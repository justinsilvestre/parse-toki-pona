import fs from 'fs'
import path from 'path'
import peg from 'pegjs'
import expect from 'expect'
import { transform } from 'babel-core'

const grammarText = fs.readFileSync(path.join(__dirname, '..', 'tokipona.pegjs'), 'utf8')
const parser = eval(transform(peg.generate(grammarText, {output: 'source'}), { plugins: ["transform-object-rest-spread"] }).code)
const parse = (text) => parser.parse(text)[0]

function wordsFrom(parsedSentence) {
  return parsedSentence.map(({ word }) => word)
}

function idAt(wordIndex, [parsedSentence]) {
  return parsedSentence[wordIndex].id
}

describe('parser', () => {
  it('parses a simple sentence', () => {
    const [toki] = parse('toki')

    expect(toki).toInclude({
      word: 'toki',
      role: 'predicate'
    })
    expect(toki.id).toExist()
  })

  it('parses a phrase with single simple complement', () => {
    const [toki, pona] = parse('toki pona')

    expect(pona).toInclude({
      word: 'pona',
      role: 'complement',
      head: toki.id,
    })
  })

  it('parses a phrase with single complex complement', () => {
    const [toki, pi, pona, mute] = parse('toki pi pona mute')

    expect(pona.head).toBe(toki.id)
    expect(mute.head).toBe(pona.id)
  })

  it('parses a simple predicate', () => {
    const [toki, li, pona] = parse('toki li pona')

    expect(pona).toInclude({
      role: 'predicate'
    })
  })

  it('parses a simple subject', () => {
    const [toki, li, pona] = parse('toki li pona')

    expect(toki).toInclude({
      role: 'subject'
    })
  })

  it('parses a microsubject', () => {
    const [mi, pona] = parse('mi pona')

    expect(mi).toInclude({
      role: 'subject'
    })
  })

  it('parses a predicate in microsubject sentence', () => {
    const [mi, pona] = parse('mi pona')

    expect(pona).toInclude({
      role: 'predicate'
    })
  })

  it('parses a complemented mi or sina as complex subject', () => {
    const [mi, mute, li, pona] = parse('mi mute li pona')

    expect(mute).toInclude({
      role: 'complement',
      head: mi.id
    })
  })
})
