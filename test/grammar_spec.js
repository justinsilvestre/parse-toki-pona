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
    typeof v === 'string'
      ? v
      : [v.before, v.text, v.after].filter(v=>v).join('')
  ).filter(v=>v).join(' ')
  if (reconstructed !== text) {
    console.log(data)
    throw new Error('A word is missing here! '
      + `Compare "${reconstructed}" to "${text}"`)
  }

  const noId = data.find(v => !v.id)
  if (noId) throw new Error(`Word is lacking id: ${noId}`)

  return data
}

const getRole = (word) => word.role

describe('parser', () => {
  it('parses a simple sentence', () => {
    const [toki] = parse('toki')

    expect(toki).toInclude({
      text: 'toki',
      role: 'predicate'
    })
    expect(toki.id).toExist()
  })

  it('parses a phrase with single simple complement', () => {
    const [toki, pona] = parse('toki pona')

    expect(pona).toInclude({
      text: 'pona',
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

    expect([toki, pali].map(getRole)).toEqual(['subject', 'subject'])
  })

  it('parses a microsubject', () => {
    const [mi, pona] = parse('mi pona')

    expect(mi).toInclude({
      role: 'subject'
    })
  })

  it('links subject to proper context predicate', () => {
    const [ken, la, ona, en, sina, li, pona, , mi, kama] = parse('ken la ona en sina li pona la mi kama')

    expect([ona, sina].map(w => w.context)).toEqual([pona.context, pona.context])
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

  it('parses a pre-verb with infinitive', () => {
    const [sina, ken, pona] = parse('sina ken pona')

    expect([ken, pona].map(getRole)).toEqual(['predicate', 'infinitive'])
  })

  it('parses a prepositional predicate', () => {
    const [sina, lon, sewi] = parse('sina lon sewi')

    expect([lon, sewi].map(getRole)).toEqual(['predicate', 'prepositional_object'])
  })

  it('parses a prepositional complement with pi', () => {
    const [jan, pi, lon, tomo, li, wawa] = parse('jan pi lon tomo li wawa')

    expect(lon).toInclude({
      role: 'complement',
      head: jan.id
    })
    expect(tomo).toInclude({ role: 'prepositional_object' })
  })

  it('parses a preposition as transitive verb in presence of direct object', () => {
    const [mi, tawa, wawa, e, kiwen] = parse('mi tawa wawa e kiwen')

    expect([tawa, wawa].map(getRole)).toEqual(['predicate', 'complement'])
  })

  it('parses a prepositional phrase outside of predicate head', () => {
    const [ona, li, moku, lon, telo, , toki, tawa, sina] = parse('ona li moku lon telo li toki tawa sina')

    expect([lon, telo, tawa, sina].map(getRole)).toEqual(['complement', 'prepositional_object', 'complement', 'prepositional_object'])
  })

  it('associates prepositional phrase outside of predicate head with correct head', () => {
    const [ona, li, moku, lon, telo, , toki, tawa, sina] = parse('ona li moku lon telo li toki tawa sina')

    expect([lon, tawa].map((w) => w.head)).toEqual([moku, toki].map((w) => w.id))

  })

  it('parses compound predicates', () => {
    const [toki, , pona, , wawa] = parse('toki li pona li wawa')

    expect([pona, wawa].map(getRole)).toEqual(['predicate', 'predicate'])
  })

  it('parses a subjectless optative predicate', () => {
    const [o, pona] = parse('o pona')

    expect([o, pona].map(getRole)).toEqual([undefined, 'predicate'])
  })

  it('parses a vocative expression in an indicative sentence', () => {
    const [jan, mute, o, ale, li, pona] = parse('jan mute o, ale li pona')

    expect(jan).toInclude({
      role: 'vocative'
    })
  })

  it('parses a lone vocative expression as sentence', () => {
    const [sewi, o] = parse('sewi o!')

    expect(sewi).toInclude({
      role: 'vocative'
    })
  })

  it('parses a lone vocative expression as sentence even without punctuation', () => {
    const [sewi, o] = parse('sewi o')

    expect(sewi).toInclude({
      role: 'vocative'
    })
  })

  it('parses questions with ala', () => {
    const [sina, pona1, ala, pona2] = parse('sina pona ala pona')

    expect([ala, pona2].map(getRole)).toEqual(['interrogative', 'interrogative_repetition'])
    expect(pona2).toInclude({ text: 'pona' })
  })

  it('parses negation', () => {
    const [ni, li, pona, ala, a] = parse('ni li pona ala a')

    expect(ala).toInclude({
      role: 'negative',
      head: pona.id
    })
  })

  it('parses negated preposition', () => {
    const [ike, li, lon, ala] = parse('ike li lon ala')

    expect(ala).toInclude({
      role: 'negative',
      head: lon.id
    })
  })

  it('parses negated pre-verb', () => {
    const [ijo, li, ken, ala, awen] = parse('ijo li ken ala awen')

    expect([ken, ala, awen].map(getRole)).toEqual(['predicate', 'negative', 'infinitive'])
  })

  it('parses anu phrase in subject', () => {
    const [kili, anu, pan, li, pona] = parse('kili anu pan li pona')

    expect([kili, pan].map(getRole)).toEqual(['subject', 'subject'])
  })

  it('parses anu phrase in predicate', () => {
    const [moku, li, ko, anu, telo] = parse('moku li ko anu telo')

    expect([ko, telo].map(getRole)).toEqual(['predicate', 'predicate'])
  })

  it('parses proper nouns', () => {
    const [jan, Sonja, li, mama, pi, toki, pona] = parse('jan Sonja li mama pi toki pona')

    expect(Sonja).toInclude({
      text: 'Sonja',
      role: 'complement'
    })
  })

  it('accepts sentence before subjectless imperative sentence', () => {
    parser.parse('toki! o lukin e lipu ni!')
  })

  it('counts head of pi-complement as complement', () => {
    const [toki, li, ijo, pi, pona, mute] = parse('toki li ijo pi pona mute')

    expect(pona).toInclude({
      role: 'complement',
      head: ijo.id,
    })
  })
})
