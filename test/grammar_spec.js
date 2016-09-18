import fs from 'fs'
import path from 'path'
import peg from 'pegjs'
import expect from 'expect'
import { transform } from 'babel-core'

const grammarText = fs.readFileSync(path.join(__dirname, '..', 'tokipona.pegjs'), 'utf8')
const parser = eval(transform(peg.generate(grammarText, {output: 'source'}), { plugins: ["transform-object-rest-spread"] }).code)
const parse = (text) => {
  const data = parser.parse(text)[0]

  const reconstructed = data.map(v =>
    typeof v === 'string' ? v : (v.word || v.text)
  ).filter(v=>v).join(' ')
  if (reconstructed !== text)
    throw new Error('A word is missing here!'
      + `Compare "${reconstructed}" to "${text}"`)

  return data
}

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

  it('parses a phrase with single complements', () => {
    const [toki, pona, lili] = parse('toki pona lili')

    expect(lili).toInclude({
      role: 'complement',
      head: toki.id,
    })
  })

  it('parses a phrase with single complex complement', () => {
    const [toki, pi, pona, mute] = parse('toki pi pona mute')

    expect(pona.head).toBe(toki.id)
    expect(mute.head).toBe(pona.id)
  })

  it('parses a phrase with complex complements', () => {
    const parsed = parse('toki pona pi lili mute pi sona sewi')
    const [toki, pona, , lili, mute, , sona, sewi] = parsed

    expect([pona, lili, sona].map(w => w.head)).toEqual([toki.id, toki.id, toki.id])
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

  it('parses a compound subject', () => {
    const [toki, en, pali] = parse('mi en sina li pona')

    expect([toki, pali].map(w => w.role)).toEqual(['subject', 'subject'])
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

  it('parses a sentence with context', () => {
    const [ken, la, sina, pona] = parse('ken la sina pona')

    expect(ken).toInclude({
      role: 'context_predicate'
    })
  })

  it('parses direct object', () => {
    const [mi, moku, e, pan] = parse('mi moku e pan')

    expect(pan).toInclude({
      role: 'direct_object'
    })
  })
})
