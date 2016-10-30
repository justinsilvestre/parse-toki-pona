{ // get options for alternative searching
  const { v4 } = require('uuid')
  const m = (...objs) => Object.assign({}, ...objs)
  const flatten = (arrs) => arrs.reduce((a, b) => a.concat(b), [])
  const last = (arr) => arr[arr.length - 1]
  const init = (arr) => arr.slice(0, arr.length - 1)
  const cast = (words, role) => words.map((w, i) => (i === 0 || words[i - 1] === 'anu') ? m(w, { role }) : w)

  const isSubstantive = (val) => typeof val !== 'string'
  const word = (text) => ({ text, id: v4()})
  const phrase = (first, alternate) => [...first, ...(alternate ? ['anu', ...alternate] : [])]
  const complements = (head) => (c) => m(c, { role: c.role || 'complement', head: c.head || head.id }) // test this works with anu
  const vocative = (words) => cast(words, 'vocative')
  const predicate = (words) => {
    const finalPPs = flatten(last(words).finalPPs || []).map(complements(words[0]))
    return cast([...words, ...finalPPs], 'predicate')
  }
  const complement = (words) => cast(words, 'complement')
  const subject = (words) => cast(words, 'subject')
  const endPunctuation = (text = '') => ({ role: 'end_punctuation', text })
  const punctuate = ({ before, after }, word) => m(
    before ? { before } : {},
    after ? { after } : {},
    word
  )

  const punctuateLast = (after, phrase) => [...init(phrase), punctuate({ after }, last(phrase))]
  const context = (clause) => clause.map(w => {
    if (!w.role)
      return w

    return (w.role === 'subject' || w.role === 'predicate')
      ? m(w, { role: `context_${w.role}` })
      : w
  })
  const infinitive = (words) => cast(words, 'infinitive')
  const directObject = (words) => cast(words, 'direct_object')
  const prepositionalObject = (words) => cast(words, 'prepositional_object')
  const negative = (ala) => ala ? [{ text: 'ala', role: 'negative' }] : []
  const interrogative = (s) => [{ text: 'ala', role: 'interrogative' }, { text: s.text, role: 'interrogative' }]

  const vocativeParticle = { text: 'o', role: 'vocative_particle' }

  const tagWithFinalPPs = (words, finalPPs) => [...init(words), m(last(words), { finalPPs })]
}

/* TODO: ACCOMMODATE COMMAS */

Sentences
  = s:Sentence+ { return s }

Sentence
  = v:Vocative? cs:Context* c:Clause ep:EndPunctuation
    { return [...(v || []), ...flatten(cs), ...punctuateLast(ep, [...c])] }
  / v:Vocative ep:EndPunctuation { return [...punctuateLast(ep, [...v])] }

Vocative
  = p:Phrase 'o' pu:[\,\!] { return [...vocative(p), punctuate({ after: pu }, vocativeParticle)] }

Context
  = c:Clause 'la' { return [...context(c), 'la'] }

Clause
  = sp:SubjectAndParticle p:Predicate aps:AdditionalPredicate* { return [...sp, ...p, ...flatten(aps)] }
  / ms:MS p:Predicate { return [...subject([word(ms)]), ...p] }
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
  = vp:VerbalPhrase dos:DirectObject+ { return predicate([...vp, ...flatten(dos) ])}
  / prep:PrepositionalPhrase { return predicate(prep) }
  / vp:VerbalPhrase { return predicate(vp) }


AdditionalPredicate
  = mp:ModalParticle p:Predicate { return [mp, ...p] }

VerbalPhrase
  = pv:PreVerbWithPolarity vp:VerbalPhrase { return [...pv, ...infinitive(vp)] }
  / p:Phrase { return p }

PrepositionalPhrase
  = prep:PrepositionWithPolarity p:Phrase { return [...complement(prep), ...prepositionalObject(p)] }

EndPunctuation
  = [\.\?\!]+ { return text() }
  / !. { return '' }

DirectObject
  = 'e' p:Phrase { return ['e', ...directObject(p)] }

Phrase
  = cp:ComplexPhrase alternate:Alternate? { return phrase(cp, alternate) }
  / ss:SubstantiveString alternate:Alternate? { return phrase(ss, alternate) }

Alternate
  = _? anu:'anu' p:Phrase { return p }

ComplexPhrase
  = ss:SubstantiveString cc:ComplexComplement+  {
    return [...ss,
    ...flatten(cc.map(([pi, subHead, ...rest]) => [pi, m(subHead, { head: ss[0].id }), ...rest]))
    ] }

ComplexComplement
  = 'pi' pp:PrepositionalPhrase { return ['pi', ...pp] }
  / 'pi' ss:SubstantiveString { return ['pi', ...ss]}

SubstantiveString
  = s:SubstantiveWithPolarity pps:(PrepositionalPhrase)+ PredicateEnd { const [head, ...rest] = flatten(s); return tagWithFinalPPs([head, ...rest.map(complements(head))], pps) }
  / s:SubstantiveWithPolarity+ { const [head, ...rest] = flatten(s); return [head, ...rest.map(complements(head))] }

PredicateEnd
  =  !(!(EndPunctuation / 'li' / 'o'))

SubstantiveWithPolarity
  = s1:Substantive ala:Ala s2:Substantive & { return s1.text === s2.text } { return [s1, ...interrogative(s1)] }
  / s:Substantive ala:Ala? { return [s, ...negative(ala)]}

PreVerbWithPolarity
  = pv1:PV ala:Ala pv2:PV & { return pv1 === pv2 } { return [word(pv1), ...interrogative(pv2)] }
  / pv:PV ala:Ala? { return [word(pv), ...negative(ala)]}

PrepositionWithPolarity
  = prep:PREP ala:Ala prep2:PREP & { return prep1 === prep2 } { return [word(prep1), ...interrogative(prep2)] }
  / prep:PREP ala:Ala? { return [word(prep), ...negative(ala)] }

Substantive
  = NativeSubstantive / ProperNoun

NativeSubstantive
  = s:(MS / PV / PREP / CS) { return word(s) }

ProperNoun
  = _? f:([A-Z])r:([a-z]i+) _ { return word([f, ...r].join(''))}

CS "common substantive"
  = _? x:('sitelen'/'kalama'/'soweli'/'pimeja'/'kulupu'/'sijelo'/'sinpin'
  /'pakala'/'palisa'/'namako'/'monsi'/'kiwen'/'utala'/'linja'/'pilin'
  /'akesi'/'tenpo'/'nanpa'/'nasin'/'alasa'/'musi'/'suli'/'kule'
  /'sike'/'suno'/'sewi'/'seme'/'selo'/'seli'/'insa'/'pona'/'poki'/'poka'
  /'pipi'/'pini'/'supa'/'suwi'/'pana'/'wile'/'pali'/'taso'/'open'/'ante'
  /'olin'/'kili'/'noka'/'nimi'/'waso'/'nena'/'nasa'/'telo'/'toki'/'mute'
  /'tomo'/'esun'/'kasi'/'moli'/'moku'/'mije'/'wawa'/'meli'/'mani'/'mama'
  /'kala'/'lupa'/'unpa'/'luka'/'anpa'/'loje'/'lipu'/'jelo'/'lili'/'lete'/'weka'
  /'lawa'/'laso'/'lape'/'jaki'/'kute'/'walo'/'kon'/'ali'/'pan'/'ona'/'oko'
  /'jan'/'mun'/'ilo'/'ike'/'ijo'/'ale'/'uta'/'len'/'sin'/'wan'
  /'kin'/'ma'/'ni'/'mu'/'tu'/'pu'/'ko'/'jo'/'a') _ { return x }

MS "microsubject"
  = _? x:('mi'/'sina') _ { return x }

PV "pre-verb"
  = _? x:('awen'/'kama'/'ken'/'lukin'/'sona') _ { return x }

PREP "preposition"
  = _? x:('kepeken'/'lon'/'sama'/'tan'/'tawa') _ { return x }

Ala
  = _? ala:'ala' _ { return ala }

Anu
  = _? anu:'anu' _ { return anu }

_ "whitespace"
  = [\n\r\t ]+ / ![a-zA-Z]+

EOF
  = !.
