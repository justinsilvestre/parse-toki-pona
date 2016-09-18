{
  const { v4 } = require('uuid')
  const flatten = (arrs) => arrs.reduce((a, b) => a.concat(b), [])

  const isSubstantive = (val) => typeof val !== 'string'
  const word = (text) => ({ word: text, id: v4()})
  const complements = (head) => (c) => ({ ...c, role: 'complement', head: c.head || head.id })
  const predicate = ([head, ...rest]) => [{ ...head, role: 'predicate' }, ...rest]
  const subject = ([head, ...rest]) => [{ ...head, role: 'subject' }, ...rest]
  const endPunctuation = (text) => ({ role: 'end_punctuation', text })
  const context = (clause) => clause.map(w => {
    if (!w.role)
      return w

    return (w.role === 'subject' || w.role === 'predicate')
      ? { ...w, role: `context_${w.role}` }
      : w
  })
  const directObject = ([head, ...rest]) => [{ ...head, role: 'direct_object' }, ...rest]
}

/* TODO: ACCOMODATE COMMAS */

Sentences
  = s:Sentence+ { return s }

Sentence
  = cs:Context* _ c:Clause _ ep:EndPunctuation { return [...flatten(cs), ...c, endPunctuation(ep)] }

Context
  = c:Clause _ 'la' { return context(c) }

Clause
  = sp:SubjectAndParticle  _ p:Predicate { return [...sp, ...p] }
  / ms:MS _ p:Predicate { return [...subject([word(ms)]), ...p] }
  / p:Predicate { return [...p] }

Predicate
  = p:Phrase dos:DirectObject* { return [...predicate(p), ...flatten(dos.map(directObject)) ]}

EndPunctuation
  = [\.\?\!]+ { return text() }
  / ! { return '' }

SubjectAndParticle
  = s:Phrase _ mp:ModalParticle { return [...subject(s), mp] }

ModalParticle
  = 'li'
  / 'o'

DirectObject
  = 'e' p:Phrase { return ['e', ...directObject(p)] }

Phrase
  = phrase:ComplexPhrase { return phrase }
  / phrase:SubstantiveString { return phrase }

SimplePhrase
  = word:Substantive { return [word]  }

ComplexPhrase
  = ss:SubstantiveString _ cc:ComplexComplement+ {
    return [...ss,
    ...flatten(cc.map(([pi, subHead, ...rest]) => [pi, { ...subHead, head: ss[0].id }, ...rest]))
    ] }

ComplexComplement
  = _ 'pi' _ ss:SubstantiveString _ { return ['pi', ...ss]}

SubstantiveString
  = s:Substantive+ { const [head, ...rest] = s; return [head, ...rest.map(complements(head))] }

Substantive
  = _ cs:CS _ { return word(cs) }
  / _ ms:MS _ { return word(ms)}
  / _ pv:PV _ { return word(pv)}

CS "common substantive"
  = 'sitelen'/'kepeken'/'kalama'/'soweli'/'pimeja'/'kulupu'/'sijelo'/'sinpin'
  /'pakala'/'palisa'/'namako'/'monsi'/'kiwen'/'utala'/'linja'/'pilin'
  /'akesi'/'tenpo'/'nanpa'/'nasin'/'alasa'/'musi'/'suli'/'kule'
  /'sike'/'suno'/'sewi'/'seme'/'selo'/'seli'/'sama'/'insa'/'pona'/'poki'/'poka'
  /'pipi'/'pini'/'supa'/'suwi'/'pana'/'wile'/'pali'/'taso'/'open'/'ante'
  /'olin'/'kili'/'noka'/'nimi'/'waso'/'nena'/'tawa'/'nasa'/'telo'/'toki'/'mute'
  /'tomo'/'esun'/'kasi'/'moli'/'moku'/'mije'/'wawa'/'meli'/'mani'/'mama'
  /'kala'/'lupa'/'unpa'/'luka'/'anpa'/'loje'/'lipu'/'jelo'/'lili'/'lete'/'weka'
  /'lawa'/'laso'/'lape'/'jaki'/'kute'/'walo'/'kon'/'ali'/'pan'/'tan'/'ona'/'oko'
  /'jan'/'mun'/'ilo'/'ike'/'ijo'/'ale'/'lon'/'uta'/'len'/'sin'/'ala'/'anu'/'wan'
  /'kin'/'ma'/'ni'/'mu'/'tu'/'pu'/'ko'/'jo'/'en'/'a'

MS "microsubject"
  = 'mi'/'sina'

PV "pre-verb"
  = 'awen'/'kama'/'ken'/'lukin'/'sona'

_ "whitespace"
  = [ \t\n\r]*
