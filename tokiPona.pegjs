{ // get options for alternative searching
  const { v4 } = require('uuid')
  const flatten = (arrs) => arrs.reduce((a, b) => a.concat(b), [])
  const last = (arr) => arr[arr.length - 1]
  const init = (arr) => arr.slice(0, arr.length - 1)

  const isSubstantive = (val) => typeof val !== 'string'
  const word = (text) => ({ text, id: v4()})
  const complements = (head) => (c) => ({ ...c, role: c.role || 'complement', head: c.head || head.id })
  const vocative = ([head, ...rest]) => [{ ...head, role: 'vocative' }, ...rest]
  const predicate = ([head, ...rest]) => [{ ...head, role: 'predicate' }, ...rest]
  const complement = ([head, ...rest]) => [{ ...head, role: 'complement' }, ...rest]
  const subject = ([head, ...rest]) => [{ ...head, role: 'subject' }, ...rest]
  const endPunctuation = (text = '') => ({ role: 'end_punctuation', text })
  const punctuate = ({ before, after }, word) => ({
    ...(before ? { before } : {}),
    ...(after ? { after } : {}),
    ...word
  })
  const punctuateLast = (after, phrase) => [...init(phrase), punctuate({ after }, last(phrase))]
  const context = (clause) => clause.map(w => {
    if (!w.role)
      return w

    return (w.role === 'subject' || w.role === 'predicate')
      ? { ...w, role: `context_${w.role}` }
      : w
  })
  const infinitive = ([head, ...restOfVerbalPhrase]) => [{ ...head, role: 'infinitive' }, ...restOfVerbalPhrase]
  const directObject = ([head, ...rest]) => [{ ...head, role: 'direct_object' }, ...rest]
  const prepositionalObject = ([head, ...rest]) => [{ ...head, role: 'prepositional_object' }, ...rest]
  const negative = (ala) => ala ? [{ text: 'ala', role: 'negative' }] : []
  const interrogative = (s) => [{ text: 'ala', role: 'interrogative' }, { text: s.text, role: 'interrogative' }]

  const vocativeParticle = { text: 'o', role: 'vocative_particle' }
}

/* TODO: ACCOMMODATE COMMAS */

Sentences
  = s:Sentence+ { return s }

Sentence
  = v:Vocative? cs:Context* c:Clause qm:QuestionMarker ep:EndPunctuation
    { return [...(v || []), ...flatten(cs), ...punctuateLast(ep, [...c, ...qm])] }
  / v:Vocative qm:QuestionMarker ep:EndPunctuation { return [...punctuateLast(ep, [...v, ...qm])] }

QuestionMarker
  = as:(Anu Seme)? { return as ? [{ text: 'anu seme', role: 'question_marker' }] : [] }

Vocative
  = p:Phrase 'o' _ pu:[\,\!] { return [...vocative(p), punctuate({ after: pu }, vocativeParticle)] }

Context
  = c:Clause 'la' { return [...context(c), 'la'] }

Clause
  = sp:SubjectAndParticle p:Predicate aps:AdditionalPredicate* { return [...sp, ...p, ...flatten(aps)] }
  / _ ms:MS p:Predicate { return [...subject([word(ms)]), ...p] }
  / op:OptativeParticle p:Predicate aps:AdditionalPredicate* { return [...op, ...p, ...flatten(aps)] }
                                    // properly, this should only be with 'o'
  / p:Predicate { return p }

SubjectAndParticle
  = s:Phrase ass:AdditionalSubject* mp:ModalParticle { return [...subject(s), ...flatten(ass), mp] }

AdditionalSubject
  = 'en' s:Phrase { return ['en', ...subject(s)] }

ModalParticle
  = 'li'
  / OptativeParticle { return 'o' }

OptativeParticle
  = 'o'

Predicate
  = vp:PredicateVerbalPhrase dos:DirectObject+ { return [...vp, ...flatten(dos) ]}
  / prep:PrepositionalPhrase { const [first, ...rest] = prep; return [{ ...first, role: 'predicate' }, ...rest] }
  // but multiple prep phrases?
  / vp:PredicateVerbalPhrase { return vp }

AdditionalPredicate
  = mp:ModalParticle p:Predicate { return [mp, ...p] }

PredicateVerbalPhrase
  = pv:PreVerbWithPolarity vp:PredicateVerbalPhrase { return [...predicate(pv), ...infinitive(vp)] }
  / p:Phrase { return predicate(p) }

PrepositionalPhrase
  = prep:PrepositionWithPolarity p:Phrase { return [...complement(prep), ...prepositionalObject(p)] }

EndPunctuation
  = [\.\?\!]+ { return text() }
  / ! { return '' }

DirectObject
  = 'e' p:Phrase { return ['e', ...directObject(p)] }

Phrase
  = phrase:ComplexPhrase { return phrase }
  / phrase:SubstantiveString { return phrase }

ComplexPhrase
  = ss:SubstantiveString cc:ComplexComplement+ {
    return [...ss,
    ...flatten(cc.map(([pi, subHead, ...rest]) => [pi, { ...subHead, head: ss[0].id }, ...rest]))
    ] }

ComplexComplement
  = 'pi' pp:PrepositionalPhrase { return ['pi', ...pp] }
  / 'pi' ss:SubstantiveString { return ['pi', ...ss]}

SubstantiveString
= s:SubstantiveWithPolarity+ { const [head, ...rest] = flatten(s); return [head, ...rest.map(complements(head))] }

SubstantiveWithPolarity
  = s1:Substantive ala:Ala s2:Substantive & { return s1.text === s2.text } { return [s1, ...interrogative(s1)] }
  / s:Substantive ala:Ala? { return [s, ...negative(ala)]}

PreVerbWithPolarity
  = _ pv1:PV ala:Ala pv2:PV _ & { return pv1 === pv2 } { return [word(pv1), ...interrogative(pv2)] }
  / _ pv:PV ala:Ala? { return [word(pv), ...negative(ala)]}

PrepositionWithPolarity
  = _ prep:PREP ala:Ala? { return [word(prep), ...negative(ala)] }

Substantive
  = NativeSubstantive / ProperNoun

NativeSubstantive
  = _ s:(MS / PV / PREP / CS / Seme) _ { return word(s) }

ProperNoun
  = _ f:([A-Z])r:([a-z]i+) _ { return word([f, ...r].join(''))}

CS "common substantive"
  = 'sitelen'/'kalama'/'soweli'/'pimeja'/'kulupu'/'sijelo'/'sinpin'
  /'pakala'/'palisa'/'namako'/'monsi'/'kiwen'/'utala'/'linja'/'pilin'
  /'akesi'/'tenpo'/'nanpa'/'nasin'/'alasa'/'musi'/'suli'/'kule'
  /'sike'/'suno'/'sewi'/'seme'/'selo'/'seli'/'insa'/'pona'/'poki'/'poka'
  /'pipi'/'pini'/'supa'/'suwi'/'pana'/'wile'/'pali'/'taso'/'open'/'ante'
  /'olin'/'kili'/'noka'/'nimi'/'waso'/'nena'/'nasa'/'telo'/'toki'/'mute'
  /'tomo'/'esun'/'kasi'/'moli'/'moku'/'mije'/'wawa'/'meli'/'mani'/'mama'
  /'kala'/'lupa'/'unpa'/'luka'/'anpa'/'loje'/'lipu'/'jelo'/'lili'/'lete'/'weka'
  /'lawa'/'laso'/'lape'/'jaki'/'kute'/'walo'/'kon'/'ali'/'pan'/'ona'/'oko'
  /'jan'/'mun'/'ilo'/'ike'/'ijo'/'ale'/'uta'/'len'/'sin'/'wan'
  /'kin'/'ma'/'ni'/'mu'/'tu'/'pu'/'ko'/'jo'/'a'

MS "microsubject"
  = 'mi'/'sina'

PV "pre-verb"
  = 'awen'/'kama'/'ken'/'lukin'/'sona'

PREP "preposition"
  = 'kepeken'/'lon'/'sama'/'tan'/'tawa'

Ala
  = _ ala:'ala' _ { return ala }

Anu
  = _ anu:'anu' _ { return anu }

Seme
  = _ seme:'seme' _ { return seme }

_ "whitespace"
  = [ \t\n\r]*
