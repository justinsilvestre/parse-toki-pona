{
  const { v4 } = require('uuid')
  const flatten = (arrs) => arrs.reduce((a, b) => a.concat(b), [])

  const isSubstantive = (val) => typeof val !== 'string'
  const word = (text) => ({ word: text, id: v4()})
  const complements = (head) => (c) => ({ ...c, role: c.role || 'complement', head: c.head || head.id })
  const vocative = ([head, ...rest]) => [{ ...head, role: 'vocative' }, ...rest]
  const predicate = ([head, ...rest]) => [{ ...head, role: 'predicate' }, ...rest]
  const subject = ([head, ...rest]) => [{ ...head, role: 'subject' }, ...rest]
  const endPunctuation = (text = '') => ({ role: 'end_punctuation', text })
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
  const negative = (ala) => ala ? [{ word: 'ala', role: 'negative' }] : []
  const interrogative = (s) => [{ word: 'ala', role: 'interrogative' }, { word: s.word, role: 'interrogative' }]
}

/* TODO: ACCOMODATE COMMAS */

Sentences
  = s:Sentence+ { return s }

Sentence
  = v:Vocative? cs:Context* c:Clause ep:EndPunctuation
    { return [...(v || []), ...flatten(cs), ...c, endPunctuation(ep)] }
  / v:Vocative ep:EndPunctuation { return [...v, endPunctuation(ep)] }

Vocative
  = p:Phrase 'o' _ pu:[\,\!] { return [...vocative(p), 'o' + pu] }

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
  = vp:VerbalPhrase dos:DirectObject+ { return [...vp, ...flatten(dos) ]}
  / prep:PrepositionWithPolarity p:Phrase { return [...predicate(prep), ...prepositionalObject(p)] }
  / vp:VerbalPhrase { return vp }

AdditionalPredicate
  = mp:ModalParticle p:Predicate { return [mp, ...p] }

VerbalPhrase
  = _ pv:PV vp:VerbalPhrase { return [...predicate([word(pv)]), ...infinitive(vp)] }
  / p:Phrase { return predicate(p) }

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
  = 'pi' ss:SubstantiveString { return ['pi', ...ss]}

SubstantiveString
= s:SubstantiveWithPolarity+ { const [head, ...rest] = flatten(s); return [head, ...rest.map(complements(head))] }

SubstantiveWithPolarity
  = s1:Substantive ala:Ala s2:Substantive & { return s1.word === s2.word } { return [s1, ...interrogative(s1)] }
  / s:Substantive ala:Ala? { return [s, ...negative(ala)]}

  /*PreVerbWithPolarity
    = _ pv:PV _ ala:Ala? { const neg = ala ? [word('ala')] : []; return [pv, ...neg]}*/

PrepositionWithPolarity
  = _ prep:PREP _ ala:Ala? { return [word(prep), ...negative(ala)] }

Substantive
  = _ ms:MS _ { return word(ms)}
  / _ pv:PV _ { return word(pv)}
  / _ prep:PREP _ { return word(prep) }
  / _ cs:CS _ { return word(cs) }

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
  /'jan'/'mun'/'ilo'/'ike'/'ijo'/'ale'/'uta'/'len'/'sin'/'anu'/'wan'
  /'kin'/'ma'/'ni'/'mu'/'tu'/'pu'/'ko'/'jo'/'a'

MS "microsubject"
  = 'mi'/'sina'

PV "pre-verb"
  = 'awen'/'kama'/'ken'/'lukin'/'sona'

PREP "preposition"
  = 'kepeken'/'lon'/'sama'/'tan'/'tawa'

Ala
  = 'ala'

_ "whitespace"
  = [ \t\n\r]*
