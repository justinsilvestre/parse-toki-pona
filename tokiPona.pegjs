{
  const { v4 } = require('uuid')

  const isSubstantive = (val) => typeof val !== 'string'
  const word = (text) => ({ word: text, id: v4()})
  const complements = (head) => (c) => ({ ...c, role: 'complement', head: c.head || head.id })
  const predicate = ([head, ...rest]) => [{ ...head, role: 'predicate' }, ...rest]
  const subject = ([head, ...rest]) => [{ ...head, role: 'subject' }, ...rest]
  const endPunctuation = (text) => ({ role: 'end_punctuation', text })
}

Sentences
  = s:Sentence+ { return s }

Sentence
  = sp:SubjectAndParticle  _ p:Phrase _ ep:EndPunctuation { return [...sp, ...predicate(p), endPunctuation(ep)] }
  / ms:MS _ p:Phrase _ ep:EndPunctuation { return [...subject([word(ms)]), ...predicate(p), endPunctuation(ep)] }
  / p:Phrase _ ep:EndPunctuation { return [...predicate(p), endPunctuation(ep)] }

EndPunctuation
  = [\.\?\!]+ { return text() }
  / ! { return '' }

SubjectAndParticle
  = s:Phrase _ mp:ModalParticle { return [...subject(s), mp] }

ModalParticle
  = 'li'
  / 'o'

Phrase
  = phrase:ComplexPhrase { return phrase }
  / phrase:SimplePhrase { return phrase }

SimplePhrase
  = word:Substantive { return [word]  }

ComplexPhrase
  = word:Substantive _ complement:Complement { return [word, ...complement.map(complements(word))]  }

Complement
  = 'pi' _ phrase:Phrase { return ['pi', ...phrase] }
  / head:Substantive { return [head] }

Substantive
  = cs:CS { return word(cs) }
  / ms:MS { return word(ms)}

CS "common substantive"
  = 'sitelen'/'kepeken'/'kalama'/'soweli'/'pimeja'/'kulupu'/'sijelo'/'sinpin'
  /'pakala'/'palisa'/'namako'/'monsi'/'kiwen'/'utala'/'linja'/'lukin'/'pilin'
  /'akesi'/'tenpo'/'nanpa'/'nasin'/'alasa'/'musi'/'sona'/'suli'/'kule'
  /'sike'/'suno'/'sewi'/'seme'/'selo'/'seli'/'sama'/'insa'/'pona'/'poki'/'poka'
  /'pipi'/'pini'/'supa'/'suwi'/'pana'/'awen'/'wile'/'pali'/'taso'/'open'/'ante'
  /'olin'/'kili'/'noka'/'nimi'/'waso'/'nena'/'tawa'/'nasa'/'telo'/'toki'/'mute'
  /'tomo'/'esun'/'kasi'/'kama'/'moli'/'moku'/'mije'/'wawa'/'meli'/'mani'/'mama'
  /'kala'/'lupa'/'unpa'/'luka'/'anpa'/'loje'/'lipu'/'jelo'/'lili'/'lete'/'weka'
  /'lawa'/'laso'/'lape'/'jaki'/'kute'/'walo'/'kon'/'ali'/'pan'/'tan'/'ona'/'oko'
  /'jan'/'mun'/'ilo'/'ike'/'ijo'/'ale'/'lon'/'uta'/'len'/'sin'/'ala'/'anu'/'wan'
  /'kin'/'ken'/'ma'/'ni'/'mu'/'tu'/'pu'/'la'/'ko'/'jo'/'en'/'e'/'a'

MS "microsubject"
  = 'mi'/'sina'

_ "whitespace"
  = [ \t\n\r]*
