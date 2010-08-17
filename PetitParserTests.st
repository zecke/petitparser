TestResource subclass: PPParserResource [
    | parsers |
    
    <comment: nil>
    <category: 'PetitTests-Core'>

    parserAt: aParserClass [
	"Answer a cached instance of aParserClass."

	<category: 'accessing'>
	^parsers at: aParserClass name ifAbsentPut: [aParserClass new]
    ]

    setUp [
	<category: 'running'>
	super setUp.
	parsers := Dictionary new
    ]
]



TestCase subclass: PPAbstractParseTest [
    
    <comment: nil>
    <category: 'PetitTests-Core'>

    PPAbstractParseTest class >> isAbstract [
	<category: 'testing'>
	^self name = #PPAbstractParseTest
    ]

    PPAbstractParseTest class >> packageNamesUnderTest [
	<category: 'accessing'>
	^#('PetitParser' 'PetitTests')
    ]

    assert: aParser fail: aCollection [
	<category: 'utilities'>
	| stream result |
	stream := aCollection asPetitStream.
	result := aParser parse: stream.
	self assert: result isPetitFailure.
	self assert: stream position = 0
    ]

    assert: aParser parse: aCollection [
	<category: 'utilities'>
	self 
	    assert: aParser
	    parse: aCollection
	    to: nil
	    end: aCollection size
    ]

    assert: aParser parse: aCollection end: anInteger [
	<category: 'utilities'>
	self 
	    assert: aParser
	    parse: aCollection
	    to: nil
	    end: anInteger
    ]

    assert: aParser parse: aCollection to: anObject [
	<category: 'utilities'>
	self 
	    assert: aParser
	    parse: aCollection
	    to: anObject
	    end: aCollection size
    ]

    assert: aParser parse: aParseObject to: aTargetObject end: anInteger [
	<category: 'utilities'>
	| stream result |
	stream := aParseObject asPetitStream.
	result := aParser parse: stream.
	aTargetObject isNil 
	    ifTrue: [self deny: result isPetitFailure]
	    ifFalse: [self assert: result = aTargetObject].
	self assert: stream position = anInteger
    ]

    assert: aParser parse: aParserObject toToken: from stop: to [
	<category: 'utilities'>
	| token |
	token := PPToken 
		    on: aParserObject
		    start: from
		    stop: to.
	^self 
	    assert: aParser
	    parse: aParserObject
	    to: token
    ]

    assert: aParser parse: aParserObject toToken: from stop: to end: end [
	<category: 'utilities'>
	| token |
	token := PPToken 
		    on: aParserObject
		    start: from
		    stop: to.
	^self 
	    assert: aParser
	    parse: aParserObject
	    to: token
	    end: end
    ]
]



PPAbstractParseTest subclass: PPComposedTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    comment [
	<category: 'accessing'>
	^($" asParser , $" asParser negate star , $" asParser) flatten
    ]

    identifier [
	<category: 'accessing'>
	^(#letter asParser , #word asParser star) flatten
    ]

    number [
	<category: 'accessing'>
	^($- asParser optional , #digit asParser plus 
	    , ($. asParser , #digit asParser plus) optional) flatten
    ]

    testComment [
	<category: 'testing-examples'>
	self 
	    assert: self comment
	    parse: '""'
	    to: '""'.
	self 
	    assert: self comment
	    parse: '"a"'
	    to: '"a"'.
	self 
	    assert: self comment
	    parse: '"ab"'
	    to: '"ab"'.
	self 
	    assert: self comment
	    parse: '"abc"'
	    to: '"abc"'.
	self 
	    assert: self comment
	    parse: '""a'
	    to: '""'
	    end: 2.
	self 
	    assert: self comment
	    parse: '"a"a'
	    to: '"a"'
	    end: 3.
	self 
	    assert: self comment
	    parse: '"ab"a'
	    to: '"ab"'
	    end: 4.
	self 
	    assert: self comment
	    parse: '"abc"a'
	    to: '"abc"'
	    end: 5.
	self assert: self comment fail: '"'.
	self assert: self comment fail: '"a'.
	self assert: self comment fail: '"aa'.
	self assert: self comment fail: 'a"'.
	self assert: self comment fail: 'aa"'
    ]

    testDoubledString [
	<category: 'testing'>
	| parser |
	parser := ($' asParser 
		    , (($' asParser , $' asParser) / $' asParser negate) star flatten 
			, $' asParser) 
			==> [:nodes | nodes second copyReplaceAll: '''''' with: ''''].
	self 
	    assert: parser
	    parse: ''''''
	    to: ''.
	self 
	    assert: parser
	    parse: '''a'''
	    to: 'a'.
	self 
	    assert: parser
	    parse: '''ab'''
	    to: 'ab'.
	self 
	    assert: parser
	    parse: '''a''''b'''
	    to: 'a''b'.
	self 
	    assert: parser
	    parse: '''a''''''''b'''
	    to: 'a''''b'
    ]

    testIdentifier [
	<category: 'testing-examples'>
	self 
	    assert: self identifier
	    parse: 'a'
	    to: 'a'.
	self 
	    assert: self identifier
	    parse: 'a1'
	    to: 'a1'.
	self 
	    assert: self identifier
	    parse: 'a12'
	    to: 'a12'.
	self 
	    assert: self identifier
	    parse: 'ab'
	    to: 'ab'.
	self 
	    assert: self identifier
	    parse: 'a1b'
	    to: 'a1b'.
	self 
	    assert: self identifier
	    parse: 'a_'
	    to: 'a'
	    end: 1.
	self 
	    assert: self identifier
	    parse: 'a1-'
	    to: 'a1'
	    end: 2.
	self 
	    assert: self identifier
	    parse: 'a12+'
	    to: 'a12'
	    end: 3.
	self 
	    assert: self identifier
	    parse: 'ab^'
	    to: 'ab'
	    end: 2.
	self 
	    assert: self identifier
	    parse: 'a1b*'
	    to: 'a1b'
	    end: 3.
	self assert: self identifier fail: ''.
	self assert: self identifier fail: '1'.
	self assert: self identifier fail: '1a'
    ]

    testIfThenElse [
	"S ::= if C then S else S | if C then S | X"

	<category: 'testing'>
	| start if then else cond expr parser |
	start := PPUnresolvedParser new.
	if := 'if' asParser token trim.
	then := 'then' asParser token trim.
	else := 'else' asParser token trim.
	cond := 'C' asParser token trim.
	expr := 'X' asParser token trim.
	start 
	    def: (if , cond , then , start , else , start) / (if , cond , then , start) 
		    / expr.
	parser := start end.
	self assert: parser parse: 'X'.
	self assert: parser parse: 'if C then X'.
	self assert: parser parse: 'if C then X else X'.
	self assert: parser parse: 'if C then if C then X'.
	self assert: parser parse: 'if C then if C then X else if C then X'.
	self assert: parser parse: 'if C then if C then X else X else if C then X'.
	self assert: parser
	    parse: 'if C then if C then X else X else if C then X else X'.
	self assert: parser fail: 'if C'.
	self assert: parser fail: 'if C else X'.
	self assert: parser fail: 'if C then if C'
    ]

    testLeftRecursion [
	"S ::= S 'x' S / '1'"

	<category: 'testing'>
	| parser |
	parser := PPUnresolvedParser new.
	parser 
	    def: ((parser , $x asParser , parser) / $1 asParser) memoized flatten.
	self 
	    assert: parser
	    parse: '1'
	    to: '1'.
	self 
	    assert: parser
	    parse: '1x1'
	    to: '1x1'.
	self 
	    assert: parser
	    parse: '1x1x1'
	    to: '1x1x1'.
	self 
	    assert: parser
	    parse: '1x1x1x1'
	    to: '1x1x1x1'.
	self 
	    assert: parser
	    parse: '1x1x1x1x1'
	    to: '1x1x1x1x1'.
	self 
	    assert: parser
	    parse: '1x1x1x1x1x1'
	    to: '1x1x1x1x1x1'
    ]

    testListOfIntegers [
	"S ::= S , number | number"

	<category: 'testing'>
	| number list parser |
	number := #digit asParser plus token trim 
		    ==> [:node | node value asInteger].
	list := (number separatedBy: $, asParser token trim) 
		    ==> [:node | node select: [:each | each isInteger]].
	parser := list end.
	self 
	    assert: parser
	    parse: '1'
	    to: (1 to: 1) asArray.
	self 
	    assert: parser
	    parse: '1,2'
	    to: (1 to: 2) asArray.
	self 
	    assert: parser
	    parse: '1,2,3'
	    to: (1 to: 3) asArray.
	self 
	    assert: parser
	    parse: '1,2,3,4'
	    to: (1 to: 4) asArray.
	self 
	    assert: parser
	    parse: '1,2,3,4,5'
	    to: (1 to: 5) asArray.
	self 
	    assert: parser
	    parse: '1'
	    to: (1 to: 1) asArray.
	self 
	    assert: parser
	    parse: '1, 2'
	    to: (1 to: 2) asArray.
	self 
	    assert: parser
	    parse: '1, 2, 3'
	    to: (1 to: 3) asArray.
	self 
	    assert: parser
	    parse: '1, 2, 3, 4'
	    to: (1 to: 4) asArray.
	self 
	    assert: parser
	    parse: '1, 2, 3, 4, 5'
	    to: (1 to: 5) asArray.
	self 
	    assert: parser
	    parse: '1'
	    to: (1 to: 1) asArray.
	self 
	    assert: parser
	    parse: '1 ,2'
	    to: (1 to: 2) asArray.
	self 
	    assert: parser
	    parse: '1 ,2 ,3'
	    to: (1 to: 3) asArray.
	self 
	    assert: parser
	    parse: '1 ,2 ,3 ,4'
	    to: (1 to: 4) asArray.
	self 
	    assert: parser
	    parse: '1 ,2 ,3 ,4 ,5'
	    to: (1 to: 5) asArray.
	self assert: parser fail: ''.
	self assert: parser fail: ','.
	self assert: parser fail: '1,'.
	self assert: parser fail: '1,,2'
    ]

    testNestedComments [
	"C ::= B I* E"

	"I ::= !!E (C | T)"

	"B ::= /*"

	"E ::= */"

	"T ::= ."

	<category: 'testing'>
	| begin end any inside parser |
	begin := '/*' asParser.
	end := '*/' asParser.
	any := #any asParser.
	parser := PPUnresolvedParser new.
	inside := end not , (parser / any).
	parser def: begin , inside star , end.
	self 
	    assert: parser
	    parse: '/*ab*/cd'
	    end: 6.
	self assert: parser parse: '/*a/*b*/c*/'.
	self assert: parser fail: '/*a/*b*/c'
    ]

    testNumber [
	<category: 'testing-examples'>
	self 
	    assert: self number
	    parse: '1'
	    to: '1'.
	self 
	    assert: self number
	    parse: '12'
	    to: '12'.
	self 
	    assert: self number
	    parse: '12.3'
	    to: '12.3'.
	self 
	    assert: self number
	    parse: '12.34'
	    to: '12.34'.
	self 
	    assert: self number
	    parse: '1..'
	    to: '1'
	    end: 1.
	self 
	    assert: self number
	    parse: '12-'
	    to: '12'
	    end: 2.
	self 
	    assert: self number
	    parse: '12.3.'
	    to: '12.3'
	    end: 4.
	self 
	    assert: self number
	    parse: '12.34.'
	    to: '12.34'
	    end: 5.
	self 
	    assert: self number
	    parse: '-1'
	    to: '-1'.
	self 
	    assert: self number
	    parse: '-12'
	    to: '-12'.
	self 
	    assert: self number
	    parse: '-12.3'
	    to: '-12.3'.
	self 
	    assert: self number
	    parse: '-12.34'
	    to: '-12.34'.
	self assert: self number fail: ''.
	self assert: self number fail: '-'.
	self assert: self number fail: '.'.
	self assert: self number fail: '.1'
    ]

    testPalindrome [
	"S0 ::= a S1 a | b S1 b | ...
	 S1 ::= S0 | epsilon"

	<category: 'testing'>
	| s0 s1 parser |
	s0 := PPUnresolvedParser new.
	s1 := PPUnresolvedParser new.
	s0 
	    def: ($a asParser , s1 , $a asParser) / ($b asParser , s1 , $b asParser) 
		    / ($c asParser , s1 , $c asParser).
	s1 def: s0 / nil asParser.
	parser := s0 flatten end.
	self 
	    assert: parser
	    parse: 'aa'
	    to: 'aa'.
	self 
	    assert: parser
	    parse: 'bb'
	    to: 'bb'.
	self 
	    assert: parser
	    parse: 'cc'
	    to: 'cc'.
	self 
	    assert: parser
	    parse: 'abba'
	    to: 'abba'.
	self 
	    assert: parser
	    parse: 'baab'
	    to: 'baab'.
	self 
	    assert: parser
	    parse: 'abccba'
	    to: 'abccba'.
	self 
	    assert: parser
	    parse: 'abaaba'
	    to: 'abaaba'.
	self 
	    assert: parser
	    parse: 'cbaabc'
	    to: 'cbaabc'.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'ab'.
	self assert: parser fail: 'aab'.
	self assert: parser fail: 'abccbb'
    ]

    testParseAaaBbb [
	"S0 ::= a S1 b
	 S1 ::= S0 | epsilon"

	<category: 'testing'>
	| s0 s1 parser |
	s0 := PPUnresolvedParser new.
	s1 := PPUnresolvedParser new.
	s0 def: $a asParser , s1 , $b asParser.
	s1 def: s0 / nil asParser.
	parser := s0 flatten.
	self 
	    assert: parser
	    parse: 'ab'
	    to: 'ab'.
	self 
	    assert: parser
	    parse: 'aabb'
	    to: 'aabb'.
	self 
	    assert: parser
	    parse: 'aaabbb'
	    to: 'aaabbb'.
	self 
	    assert: parser
	    parse: 'aaaabbbb'
	    to: 'aaaabbbb'.
	self 
	    assert: parser
	    parse: 'abb'
	    to: 'ab'
	    end: 2.
	self 
	    assert: parser
	    parse: 'aabbb'
	    to: 'aabb'
	    end: 4.
	self 
	    assert: parser
	    parse: 'aaabbbb'
	    to: 'aaabbb'
	    end: 6.
	self 
	    assert: parser
	    parse: 'aaaabbbbb'
	    to: 'aaaabbbb'
	    end: 8.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'b'.
	self assert: parser fail: 'aab'.
	self assert: parser fail: 'aaabb'
    ]

    testParseAaaaaa [
	"S ::= a a S | epsilon"

	<category: 'testing'>
	| s0 s1 parser |
	s0 := PPUnresolvedParser new.
	s1 := $a asParser , $a asParser , s0.
	s0 def: s1 / nil asParser.
	parser := s0 flatten.
	self 
	    assert: parser
	    parse: ''
	    to: ''.
	self 
	    assert: parser
	    parse: 'aa'
	    to: 'aa'.
	self 
	    assert: parser
	    parse: 'aaaa'
	    to: 'aaaa'.
	self 
	    assert: parser
	    parse: 'aaaaaa'
	    to: 'aaaaaa'.
	self 
	    assert: parser
	    parse: 'a'
	    to: ''
	    end: 0.
	self 
	    assert: parser
	    parse: 'aaa'
	    to: 'aa'
	    end: 2.
	self 
	    assert: parser
	    parse: 'aaaaa'
	    to: 'aaaa'
	    end: 4.
	self 
	    assert: parser
	    parse: 'aaaaaaa'
	    to: 'aaaaaa'
	    end: 6
    ]

    testParseAbAbAb [
	"S ::= (A B)+"

	<category: 'testing'>
	| parser |
	parser := ($a asParser , $b asParser) plus flatten.
	self 
	    assert: parser
	    parse: 'ab'
	    to: 'ab'.
	self 
	    assert: parser
	    parse: 'abab'
	    to: 'abab'.
	self 
	    assert: parser
	    parse: 'ababab'
	    to: 'ababab'.
	self 
	    assert: parser
	    parse: 'abababab'
	    to: 'abababab'.
	self 
	    assert: parser
	    parse: 'abb'
	    to: 'ab'
	    end: 2.
	self 
	    assert: parser
	    parse: 'ababa'
	    to: 'abab'
	    end: 4.
	self 
	    assert: parser
	    parse: 'abababb'
	    to: 'ababab'
	    end: 6.
	self 
	    assert: parser
	    parse: 'ababababa'
	    to: 'abababab'
	    end: 8.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'bab'
    ]

    testParseAbabbb [
	"S ::= (A | B)+"

	<category: 'testing'>
	| parser |
	parser := ($a asParser / $b asParser) plus flatten.
	self 
	    assert: parser
	    parse: 'a'
	    to: 'a'.
	self 
	    assert: parser
	    parse: 'b'
	    to: 'b'.
	self 
	    assert: parser
	    parse: 'ab'
	    to: 'ab'.
	self 
	    assert: parser
	    parse: 'ba'
	    to: 'ba'.
	self 
	    assert: parser
	    parse: 'aaa'
	    to: 'aaa'.
	self 
	    assert: parser
	    parse: 'aab'
	    to: 'aab'.
	self 
	    assert: parser
	    parse: 'aba'
	    to: 'aba'.
	self 
	    assert: parser
	    parse: 'baa'
	    to: 'baa'.
	self 
	    assert: parser
	    parse: 'abb'
	    to: 'abb'.
	self 
	    assert: parser
	    parse: 'bab'
	    to: 'bab'.
	self 
	    assert: parser
	    parse: 'bba'
	    to: 'bba'.
	self 
	    assert: parser
	    parse: 'bbb'
	    to: 'bbb'.
	self 
	    assert: parser
	    parse: 'ac'
	    to: 'a'
	    end: 1.
	self 
	    assert: parser
	    parse: 'bc'
	    to: 'b'
	    end: 1.
	self 
	    assert: parser
	    parse: 'abc'
	    to: 'ab'
	    end: 2.
	self 
	    assert: parser
	    parse: 'bac'
	    to: 'ba'
	    end: 2.
	self assert: parser fail: ''.
	self assert: parser fail: 'c'
    ]

    testParseAnBnCn [
	"PEGs for a non context- free language:
	 
	 a^n , b^n , c^n
	 
	 S <- &P1 P2
	 P1 <- AB 'c'
	 AB <- 'a' AB 'b' / epsilon
	 P2 <- 'a'* BC end
	 BC <- 'b' BC 'c' / epsilon"

	<category: 'testing'>
	| s p1 ab p2 bc |
	s := PPUnresolvedParser new.
	p1 := PPUnresolvedParser new.
	ab := PPUnresolvedParser new.
	p2 := PPUnresolvedParser new.
	bc := PPUnresolvedParser new.
	s def: (p1 and , p2 end) flatten.
	p1 def: ab , $c asParser.
	ab def: ($a asParser , ab , $b asParser) optional.
	p2 def: $a asParser star , bc.
	bc def: ($b asParser , bc , $c asParser) optional.
	self 
	    assert: s
	    parse: 'abc'
	    to: 'abc'.
	self 
	    assert: s
	    parse: 'aabbcc'
	    to: 'aabbcc'.
	self 
	    assert: s
	    parse: 'aaabbbccc'
	    to: 'aaabbbccc'.
	self assert: s fail: 'bc'.
	self assert: s fail: 'ac'.
	self assert: s fail: 'ab'.
	self assert: s fail: 'abbcc'.
	self assert: s fail: 'aabcc'.
	self assert: s fail: 'aabbc'
    ]

    testReturn [
	<category: 'testing-examples'>
	| number spaces return |
	number := #digit asParser plus token.
	spaces := #space asParser star.
	return := (spaces , $^ asParser token , spaces , number) 
		    ==> [:nodes | Array with: #return with: (nodes at: 4) value].
	self 
	    assert: return
	    parse: '^1'
	    to: #(#return '1').
	self 
	    assert: return
	    parse: '^12'
	    to: #(#return '12').
	self 
	    assert: return
	    parse: '^ 123'
	    to: #(#return '123').
	self 
	    assert: return
	    parse: '^  1234'
	    to: #(#return '1234').
	self assert: return fail: '1'.
	self assert: return fail: '^'
    ]
]



PPAbstractParseTest subclass: PPExtensionTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    testCharacter [
	<category: 'testing-parser'>
	| parser |
	parser := $a asParser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self assert: parser fail: 'b'
    ]

    testClosure [
	<category: 'testing-parser'>
	| parser |
	parser := [:stream | stream upTo: $s] asParser.
	self 
	    assert: parser
	    parse: ''
	    to: ''.
	self 
	    assert: parser
	    parse: 'a'
	    to: 'a'.
	self 
	    assert: parser
	    parse: 'aa'
	    to: 'aa'.
	self 
	    assert: parser
	    parse: 's'
	    to: ''.
	self 
	    assert: parser
	    parse: 'as'
	    to: 'a'.
	self 
	    assert: parser
	    parse: 'aas'
	    to: 'aa'.
	self 
	    assert: parser
	    parse: 'sa'
	    to: ''
	    end: 1.
	self 
	    assert: parser
	    parse: 'saa'
	    to: ''
	    end: 1.
	parser := 
		[:stream | 
		stream upTo: $s.
		PPFailure message: 'stream' at: stream position] 
			asParser.
	self assert: parser fail: ''.
	self assert: parser fail: 's'.
	self assert: parser fail: 'as'
    ]

    testEpsilon [
	<category: 'testing-parser'>
	| parser |
	parser := nil asParser.
	self assert: parser asParser = parser
    ]

    testOrdered [
	<category: 'testing-parser'>
	| parser |
	parser := #(1 2) asParser.
	self 
	    assert: parser
	    parse: #(1 2)
	    to: #(1 2).
	self 
	    assert: parser
	    parse: #(1 2 3)
	    to: #(1 2)
	    end: 2.
	self assert: parser fail: #().
	self assert: parser fail: #(1).
	self assert: parser fail: #(1 1).
	self assert: parser fail: #(1 1 2)
    ]

    testParser [
	<category: 'testing-parser'>
	| parser |
	parser := $a asParser.
	self assert: parser asParser = parser
    ]

    testRange [
	<category: 'testing-parser'>
	| parser |
	parser := $a - $c.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'b'
	    to: $b.
	self 
	    assert: parser
	    parse: 'c'
	    to: $c.
	self assert: parser fail: 'd'
    ]

    testStream [
	<category: 'testing-stream'>
	| stream |
	stream := 'abc' readStream asPetitStream.
	self assert: stream class = PPStream.
	self assert: stream printString = '·abc'.
	self assert: stream peek = $a.
	self assert: stream next = $a.
	self assert: stream printString = 'a·bc'.
	self assert: stream asPetitStream = stream
    ]

    testString [
	<category: 'testing-parser'>
	| parser |
	parser := 'ab' asParser.
	self 
	    assert: parser
	    parse: 'ab'
	    to: 'ab'.
	self 
	    assert: parser
	    parse: 'aba'
	    to: 'ab'
	    end: 2.
	self 
	    assert: parser
	    parse: 'abb'
	    to: 'ab'
	    end: 2.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'ac'
    ]

    testSymbol [
	<category: 'testing-parser'>
	| parser |
	parser := #any asParser.
	self assert: parser parse: 'a'.
	self assert: parser fail: ''
    ]

    testText [
	<category: 'testing-stream'>
	| stream |
	stream := 'abc' asText asPetitStream.
	self assert: stream class = PPStream
    ]

    testUnordered [
	<category: 'testing-parser'>
	| parser |
	parser := #(1 2) asSet asParser.
	self 
	    assert: parser
	    parse: #(1)
	    to: 1.
	self 
	    assert: parser
	    parse: #(2)
	    to: 2.
	self 
	    assert: parser
	    parse: #(1 2)
	    to: 1
	    end: 1.
	self 
	    assert: parser
	    parse: #(2 1)
	    to: 2
	    end: 1.
	self assert: parser fail: #().
	self assert: parser fail: #(3)
    ]
]



PPAbstractParseTest subclass: PPMappingTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    testFoldLeft2 [
	<category: 'testing'>
	| parser |
	parser := #any asParser star foldLeft: [:a :b | Array with: a with: b].
	self 
	    assert: parser
	    parse: #(#a)
	    to: #a.
	self 
	    assert: parser
	    parse: #(#a #b)
	    to: #(#a #b).
	self 
	    assert: parser
	    parse: #(#a #b #c)
	    to: #(#(#a #b) #c).
	self 
	    assert: parser
	    parse: #(#a #b #c #d)
	    to: #(#(#(#a #b) #c) #d).
	self 
	    assert: parser
	    parse: #(#a #b #c #d #e)
	    to: #(#(#(#(#a #b) #c) #d) #e)
    ]

    testFoldLeft3 [
	<category: 'testing'>
	| parser |
	parser := #any asParser star foldLeft: 
			[:a :b :c | 
			Array 
			    with: a
			    with: b
			    with: c].
	self 
	    assert: parser
	    parse: #(#a)
	    to: #a.
	self 
	    assert: parser
	    parse: #(#a #b #c)
	    to: #(#a #b #c).
	self 
	    assert: parser
	    parse: #(#a #b #c #d #e)
	    to: #(#(#a #b #c) #d #e)
    ]

    testFoldRight2 [
	<category: 'testing'>
	| parser |
	parser := #any asParser star foldRight: [:a :b | Array with: a with: b].
	self 
	    assert: parser
	    parse: #(#a)
	    to: #a.
	self 
	    assert: parser
	    parse: #(#a #b)
	    to: #(#a #b).
	self 
	    assert: parser
	    parse: #(#a #b #c)
	    to: #(#a #(#b #c)).
	self 
	    assert: parser
	    parse: #(#a #b #c #d)
	    to: #(#a #(#b #(#c #d))).
	self 
	    assert: parser
	    parse: #(#a #b #c #d #e)
	    to: #(#a #(#b #(#c #(#d #e))))
    ]

    testFoldRight3 [
	<category: 'testing'>
	| parser |
	parser := #any asParser star foldRight: 
			[:a :b :c | 
			Array 
			    with: a
			    with: b
			    with: c].
	self 
	    assert: parser
	    parse: #(#a)
	    to: #a.
	self 
	    assert: parser
	    parse: #(#a #b #c)
	    to: #(#a #b #c).
	self 
	    assert: parser
	    parse: #(#a #b #c #d #e)
	    to: #(#a #b #(#c #d #e))
    ]

    testMap1 [
	<category: 'testing'>
	| parser |
	parser := #any asParser map: [:a | Array with: a].
	self 
	    assert: parser
	    parse: #(#a)
	    to: #(#a)
    ]

    testMap2 [
	<category: 'testing'>
	| parser |
	parser := #any asParser , #any asParser 
		    map: [:a :b | Array with: b with: a].
	self 
	    assert: parser
	    parse: #(#a #b)
	    to: #(#b #a)
    ]

    testMap3 [
	<category: 'testing'>
	| parser |
	parser := #any asParser , #any asParser , #any asParser map: 
			[:a :b :c | 
			Array 
			    with: c
			    with: b
			    with: a].
	self 
	    assert: parser
	    parse: #(#a #b #c)
	    to: #(#c #b #a)
    ]
]



PPAbstractParseTest subclass: PPParserTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    testAction [
	<category: 'testing'>
	| block parser |
	block := [:char | char asUppercase].
	parser := #any asParser ==> block.
	self assert: parser block = block.
	self 
	    assert: parser
	    parse: 'a'
	    to: $A.
	self 
	    assert: parser
	    parse: 'b'
	    to: $B
    ]

    testAnd [
	<category: 'testing'>
	| parser |
	parser := 'foo' asParser flatten , 'bar' asParser flatten and.
	self 
	    assert: parser
	    parse: 'foobar'
	    to: #('foo' 'bar')
	    end: 3.
	self assert: parser fail: 'foobaz'.
	parser := 'foo' asParser and.
	self assert: parser and = parser
    ]

    testAnswer [
	<category: 'testing'>
	| parser |
	parser := $a asParser answer: $b.
	self 
	    assert: parser
	    parse: 'a'
	    to: $b.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'
    ]

    testBlock [
	<category: 'testing'>
	| parser |
	parser := [:s | s next] asParser.
	self 
	    assert: parser
	    parse: 'ab'
	    to: $a
	    end: 1.
	self 
	    assert: parser
	    parse: 'b'
	    to: $b.
	self 
	    assert: parser
	    parse: ''
	    to: nil
    ]

    testChildren [
	<category: 'testing-utilities'>
	| p1 p2 p3 |
	p1 := #lowercase asParser.
	p2 := p1 ==> #asUppercase.
	p3 := PPUnresolvedParser new.
	p3 def: p2 / p3.
	self assert: p1 children isEmpty.
	self assert: p2 children size = 1.
	self assert: p3 children size = 2
    ]

    testChoice [
	<category: 'testing'>
	| parser |
	parser := $a asParser / $b asParser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'b'
	    to: $b.
	self 
	    assert: parser
	    parse: 'ab'
	    to: $a
	    end: 1.
	self 
	    assert: parser
	    parse: 'ba'
	    to: $b
	    end: 1.
	self assert: parser fail: ''.
	self assert: parser fail: 'c'.
	self assert: parser fail: 'ca'
    ]

    testDelimitedBy [
	<category: 'testing'>
	| parser |
	parser := $a asParser delimitedBy: $b asParser.
	self 
	    assert: parser
	    parse: 'a'
	    to: #($a).
	self 
	    assert: parser
	    parse: 'aba'
	    to: #($a $b $a).
	self 
	    assert: parser
	    parse: 'ababa'
	    to: #($a $b $a $b $a).
	self 
	    assert: parser
	    parse: 'ab'
	    to: #($a $b).
	self 
	    assert: parser
	    parse: 'abab'
	    to: #($a $b $a $b).
	self 
	    assert: parser
	    parse: 'ababab'
	    to: #($a $b $a $b $a $b).
	self 
	    assert: parser
	    parse: 'ac'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'abc'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abac'
	    to: #($a $b $a)
	    end: 3.
	self 
	    assert: parser
	    parse: 'ababc'
	    to: #($a $b $a $b)
	    end: 4.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'.
	self assert: parser fail: 'c'
    ]

    testEndOfInput [
	<category: 'testing'>
	| parser |
	parser := PPEndOfInputParser on: $a asParser.
	self assert: parser end = parser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self assert: parser fail: ''.
	self assert: parser fail: 'aa'
    ]

    testEndOfInputAfterMatch [
	<category: 'testing'>
	| parser |
	parser := 'stuff' asParser end.
	self 
	    assert: parser
	    parse: 'stuff'
	    to: 'stuff'.
	self assert: parser fail: 'stufff'.
	self assert: parser fail: 'fluff'
    ]

    testEpsilon [
	<category: 'testing'>
	| parser |
	parser := nil asParser.
	self 
	    assert: parser
	    parse: ''
	    to: nil.
	self 
	    assert: parser
	    parse: 'a'
	    to: nil
	    end: 0.
	self 
	    assert: parser
	    parse: 'ab'
	    to: nil
	    end: 0
    ]

    testFailing [
	<category: 'testing'>
	| parser result |
	parser := PPFailingParser message: 'Plonk'.
	self assert: parser message = 'Plonk'.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'aa'.
	result := parser parse: 'a'.
	self assert: result message = 'Plonk'.
	self assert: result printString = 'Plonk at 0'
    ]

    testFailure [
	<category: 'testing-utilities'>
	| failure |
	failure := PPFailure message: 'Error' at: 3.
	self assert: failure message = 'Error'.
	self assert: failure position = 3.
	self assert: failure isPetitFailure.
	self deny: 4 isPetitFailure.
	self deny: 'foo' isPetitFailure
    ]

    testFlatten [
	<category: 'testing'>
	| parser |
	parser := $a asParser flatten.
	self 
	    assert: parser
	    parse: 'a'
	    to: 'a'.
	self 
	    assert: parser
	    parse: #($a)
	    to: #($a).
	self assert: parser fail: ''.
	self assert: parser fail: 'b'
    ]

    testHasProperty [
	<category: 'testing-properties'>
	| parser |
	parser := PPParser new.
	self deny: (parser hasProperty: #foo).
	parser propertyAt: #foo put: 123.
	self assert: (parser hasProperty: #foo)
    ]

    testListConstructor [
	<category: 'testing-utilities'>
	| p1 p2 p3 |
	p1 := PPChoiceParser with: $a asParser.
	p2 := PPChoiceParser with: $a asParser with: $b asParser.
	p3 := PPChoiceParser withAll: (Array 
			    with: $a asParser
			    with: $b asParser
			    with: $c asParser).
	self assert: p1 children size = 1.
	self assert: p2 children size = 2.
	self assert: p3 children size = 3
    ]

    testLiteralObject [
	<category: 'testing'>
	| parser |
	parser := PPLiteralObjectParser on: $a message: 'letter "a" expected'.
	self assert: parser literal = $a.
	self assert: parser message = 'letter "a" expected'.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self assert: parser fail: 'b'
    ]

    testLiteralObjectCaseInsensitive [
	<category: 'testing'>
	| parser |
	parser := $a asParser caseInsensitive.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'A'
	    to: $A.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'.
	self assert: parser fail: 'B'
    ]

    testLiteralSequence [
	<category: 'testing'>
	| parser |
	parser := PPLiteralSequenceParser on: 'abc'
		    message: 'sequence "abc" expected'.
	self assert: parser literal = 'abc'.
	self assert: parser message = 'sequence "abc" expected'.
	self 
	    assert: parser
	    parse: 'abc'
	    to: 'abc'.
	self assert: parser fail: 'ab'.
	self assert: parser fail: 'abd'
    ]

    testLiteralSequenceCaseInsensitive [
	<category: 'testing'>
	| parser |
	parser := 'abc' asParser caseInsensitive.
	self 
	    assert: parser
	    parse: 'abc'
	    to: 'abc'.
	self 
	    assert: parser
	    parse: 'ABC'
	    to: 'ABC'.
	self 
	    assert: parser
	    parse: 'abC'
	    to: 'abC'.
	self 
	    assert: parser
	    parse: 'AbC'
	    to: 'AbC'.
	self assert: parser fail: 'ab'.
	self assert: parser fail: 'abd'
    ]

    testMatches [
	<category: 'testing-utilities'>
	| parser |
	parser := $a asParser.
	self assert: (parser matches: 'a').
	self deny: (parser matches: 'b').
	self assert: (parser matches: 'a' readStream).
	self deny: (parser matches: 'b' readStream)
    ]

    testMatchesIn [
	<category: 'testing-utilities'>
	| parser result |
	parser := $a asParser.
	result := parser matchesIn: 'abba'.
	self assert: result size = 2.
	self assert: result first = $a.
	self assert: result last = $a.
	result := parser matchesIn: 'baaah'.
	self assert: result size = 3.
	self assert: result first = $a.
	self assert: result last = $a
    ]

    testMatchesInEmpty [
	"Empty matches should properly advance and match at each position and at the end."

	<category: 'testing-utilities'>
	| parser result |
	parser := [:stream | stream position] asParser.
	result := parser matchesIn: '123'.
	self assert: result asArray = #(0 1 2 3)
    ]

    testMatchesInOverlapping [
	"Matches that overlap should be properly reported."

	<category: 'testing-utilities'>
	| parser result |
	parser := #digit asParser , #digit asParser.
	result := parser matchesIn: 'a123b'.
	self assert: result size = 2.
	self assert: result first = #($1 $2).
	self assert: result last = #($2 $3)
    ]

    testMatchingRangesIn [
	<category: 'testing-utilities'>
	| input parser result |
	input := 'a12b1'.
	parser := #digit asParser plus.
	result := parser matchingRangesIn: input.
	self assert: result size = 3.
	result do: 
		[:each | 
		self assert: (parser matches: (input copyFrom: each first to: each last))]
    ]

    testMax [
	<category: 'testing'>
	| parser |
	parser := $a asParser max: 2.
	self assert: parser min = 0.
	self assert: parser max = 2.
	self 
	    assert: parser
	    parse: ''
	    to: #().
	self 
	    assert: parser
	    parse: 'a'
	    to: #($a).
	self 
	    assert: parser
	    parse: 'aa'
	    to: #($a $a).
	self 
	    assert: parser
	    parse: 'aaa'
	    to: #($a $a)
	    end: 2.
	self 
	    assert: parser
	    parse: 'aaaa'
	    to: #($a $a)
	    end: 2.
	self assert: (parser printString endsWith: '[0, 2]')
    ]

    testMemoized [
	<category: 'testing'>
	| count parser twice |
	count := 0.
	parser := 
		[:s | 
		count := count + 1.
		s next] asParser memoized.
	twice := parser and , parser.
	count := 0.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self assert: count = 1.
	count := 0.
	self 
	    assert: twice
	    parse: 'a'
	    to: #($a $a).
	self assert: count = 1.
	self assert: parser memoized = parser
    ]

    testMin [
	<category: 'testing'>
	| parser |
	parser := $a asParser min: 2.
	self assert: parser min = 2.
	self assert: parser max > parser min.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self 
	    assert: parser
	    parse: 'aa'
	    to: #($a $a).
	self 
	    assert: parser
	    parse: 'aaa'
	    to: #($a $a $a).
	self 
	    assert: parser
	    parse: 'aaaa'
	    to: #($a $a $a $a).
	self assert: (parser printString endsWith: '[2, *]')
    ]

    testMinMax [
	<category: 'testing'>
	| parser |
	parser := $a asParser min: 2 max: 4.
	self assert: parser min = 2.
	self assert: parser max = 4.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self 
	    assert: parser
	    parse: 'aa'
	    to: #($a $a).
	self 
	    assert: parser
	    parse: 'aaa'
	    to: #($a $a $a).
	self 
	    assert: parser
	    parse: 'aaaa'
	    to: #($a $a $a $a).
	self 
	    assert: parser
	    parse: 'aaaaa'
	    to: #($a $a $a $a)
	    end: 4.
	self 
	    assert: parser
	    parse: 'aaaaaa'
	    to: #($a $a $a $a)
	    end: 4.
	self assert: (parser printString endsWith: '[2, 4]')
    ]

    testNamed [
	<category: 'testing-accessing'>
	| parser |
	parser := PPSequenceParser new.
	self assert: parser name isNil.
	parser := PPChoiceParser named: 'choice'.
	self assert: parser name = 'choice'.
	parser := $* asParser name: 'star'.
	self assert: parser name = 'star'
    ]

    testNegate [
	<category: 'testing'>
	| parser |
	parser := 'foo' asParser negate.
	self 
	    assert: parser
	    parse: 'f'
	    to: $f
	    end: 1.
	self 
	    assert: parser
	    parse: 'fo'
	    to: $f
	    end: 1.
	self 
	    assert: parser
	    parse: 'fob'
	    to: $f
	    end: 1.
	self 
	    assert: parser
	    parse: 'ffoo'
	    to: $f
	    end: 1.
	self assert: parser fail: ''.
	self assert: parser fail: 'foo'
    ]

    testNot [
	<category: 'testing'>
	| parser |
	parser := 'foo' asParser flatten , 'bar' asParser flatten not.
	self 
	    assert: parser
	    parse: 'foobaz'
	    to: #('foo' nil)
	    end: 3.
	self assert: parser fail: 'foobar'.
	parser := 'foo' asParser.
	self assert: parser not not = parser
    ]

    testOptional [
	<category: 'testing'>
	| parser |
	parser := $a asParser optional.
	self 
	    assert: parser
	    parse: ''
	    to: nil.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'aa'
	    to: $a
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab'
	    to: $a
	    end: 1.
	self 
	    assert: parser
	    parse: 'b'
	    to: nil
	    end: 0.
	self 
	    assert: parser
	    parse: 'bb'
	    to: nil
	    end: 0.
	self 
	    assert: parser
	    parse: 'ba'
	    to: nil
	    end: 0
    ]

    testParse [
	<category: 'testing-utilities'>
	| parser result |
	parser := $a asParser.
	self assert: (parser parse: 'a') = $a.
	self assert: (result := parser parse: 'b') isPetitFailure.
	self assert: result position = 0.
	self assert: result message = '$a expected'.
	self assert: (parser parse: 'a' readStream) = $a.
	self assert: (result := parser parse: 'b' readStream) isPetitFailure.
	self assert: result position = 0.
	self assert: result message = '$a expected'
    ]

    testParseOnError0 [
	<category: 'testing-utilities'>
	| parser result seen |
	parser := $a asParser.
	result := parser parse: 'a'
		    onError: [self signalFailure: 'Not supposed to report an error'].
	self assert: result = $a.
	result := parser parse: 'b' onError: [seen := true].
	self assert: result.
	self assert: seen
    ]

    testParseOnError1 [
	<category: 'testing-utilities'>
	| parser result seen |
	parser := $a asParser.
	result := parser parse: 'a'
		    onError: [self signalFailure: 'Not supposed to report an error'].
	self assert: result = $a.
	result := parser parse: 'b'
		    onError: 
			[:failure | 
			self assert: failure position = 0.
			self assert: failure message = '$a expected'.
			seen := true].
	self assert: result.
	self assert: seen
    ]

    testParseOnError2 [
	<category: 'testing-utilities'>
	| parser result seen |
	parser := $a asParser.
	result := parser parse: 'a'
		    onError: [self signalFailure: 'Not supposed to report an error'].
	self assert: result = $a.
	result := parser parse: 'b'
		    onError: 
			[:msg :pos | 
			self assert: msg = '$a expected'.
			self assert: pos = 0.
			seen := true].
	self assert: result.
	self assert: seen
    ]

    testPermutation [
	<category: 'testing'>
	| parser |
	parser := #any asParser , #any asParser , #any asParser.
	self 
	    assert: (parser permutation: #())
	    parse: '123'
	    to: #().
	self 
	    assert: (parser permutation: #(1))
	    parse: '123'
	    to: #($1).
	self 
	    assert: (parser permutation: #(1 3))
	    parse: '123'
	    to: #($1 $3).
	self 
	    assert: (parser permutation: #(3 1))
	    parse: '123'
	    to: #($3 $1).
	self 
	    assert: (parser permutation: #(2 2))
	    parse: '123'
	    to: #($2 $2).
	self 
	    assert: (parser permutation: #(3 2 1))
	    parse: '123'
	    to: #($3 $2 $1).
	self should: [parser permutation: #(0)] raise: Error.
	self should: [parser permutation: #(4)] raise: Error.
	self should: [parser permutation: #($2)] raise: Error
    ]

    testPluggable [
	<category: 'testing'>
	| block parser |
	block := [:stream | stream position].
	parser := block asParser.
	self assert: parser block = block
    ]

    testPlus [
	<category: 'testing'>
	| parser |
	parser := $a asParser plus.
	self assert: parser min = 1.
	self assert: parser max > parser min.
	self 
	    assert: parser
	    parse: 'a'
	    to: #($a).
	self 
	    assert: parser
	    parse: 'aa'
	    to: #($a $a).
	self 
	    assert: parser
	    parse: 'aaa'
	    to: #($a $a $a).
	self 
	    assert: parser
	    parse: 'ab'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'aab'
	    to: #($a $a)
	    end: 2.
	self 
	    assert: parser
	    parse: 'aaab'
	    to: #($a $a $a)
	    end: 3.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'.
	self assert: parser fail: 'ba'
    ]

    testPlusGreedy [
	<category: 'testing'>
	| parser |
	parser := #word asParser plusGreedy: #digit asParser.
	self assert: parser fail: ''.
	self assert: parser fail: '1'.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'ab'.
	self 
	    assert: parser
	    parse: 'a1'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab1'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abc1'
	    to: #($a $b $c)
	    end: 3.
	self 
	    assert: parser
	    parse: 'a12'
	    to: #($a $1)
	    end: 2.
	self 
	    assert: parser
	    parse: 'ab12'
	    to: #($a $b $1)
	    end: 3.
	self 
	    assert: parser
	    parse: 'abc12'
	    to: #($a $b $c $1)
	    end: 4.
	self 
	    assert: parser
	    parse: 'a123'
	    to: #($a $1 $2)
	    end: 3.
	self 
	    assert: parser
	    parse: 'ab123'
	    to: #($a $b $1 $2)
	    end: 4.
	self 
	    assert: parser
	    parse: 'abc123'
	    to: #($a $b $c $1 $2)
	    end: 5
    ]

    testPlusLazy [
	<category: 'testing'>
	| parser |
	parser := #word asParser plusLazy: #digit asParser.
	self assert: parser fail: ''.
	self assert: parser fail: '1'.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'ab'.
	self 
	    assert: parser
	    parse: 'a1'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab1'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abc1'
	    to: #($a $b $c)
	    end: 3.
	self 
	    assert: parser
	    parse: 'a12'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab12'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abc12'
	    to: #($a $b $c)
	    end: 3.
	self 
	    assert: parser
	    parse: 'a123'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab123'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abc123'
	    to: #($a $b $c)
	    end: 3
    ]

    testPostCopy [
	<category: 'testing-properties'>
	| parser copy |
	parser := PPParser new.
	parser propertyAt: #foo put: true.
	copy := parser copy.
	copy propertyAt: #foo put: false.
	self assert: (parser propertyAt: #foo).
	self deny: (copy propertyAt: #foo)
    ]

    testPrint [
	<category: 'testing-accessing'>
	| parser |
	parser := PPParser new.
	self assert: (parser printString beginsWith: 'a PPParser').
	parser := PPParser named: 'choice'.
	self assert: (parser printString beginsWith: 'a PPParser(choice').
	parser := PPLiteralObjectParser on: $a.
	self assert: (parser printString includesSubString: '$a').
	parser := PPFailingParser message: 'error'.
	self assert: (parser printString includesSubString: 'error').
	parser := PPPredicateObjectParser on: [:c | true] message: 'error'.
	self assert: (parser printString includesSubString: 'error')
    ]

    testPropertyAt [
	<category: 'testing-properties'>
	| parser |
	parser := PPParser new.
	self should: [parser propertyAt: #foo] raise: Error.
	parser propertyAt: #foo put: true.
	self assert: (parser propertyAt: #foo)
    ]

    testPropertyAtIfAbsent [
	<category: 'testing-properties'>
	| parser |
	parser := PPParser new.
	self assert: (parser propertyAt: #foo ifAbsent: [true]).
	parser propertyAt: #foo put: true.
	self assert: (parser propertyAt: #foo ifAbsent: [false])
    ]

    testPropertyAtIfAbsentPut [
	<category: 'testing-properties'>
	| parser |
	parser := PPParser new.
	self assert: (parser propertyAt: #foo ifAbsentPut: [true]).
	self assert: (parser propertyAt: #foo ifAbsentPut: [false])
    ]

    testRemoveProperty [
	<category: 'testing-properties'>
	| parser |
	parser := PPParser new.
	self should: [parser removeProperty: #foo] raise: Error.
	parser propertyAt: #foo put: true.
	self assert: (parser removeProperty: #foo)
    ]

    testRemovePropertyIfAbsent [
	<category: 'testing-properties'>
	| parser |
	parser := PPParser new.
	self assert: (parser removeProperty: #foo ifAbsent: [true]).
	parser propertyAt: #foo put: true.
	self assert: (parser removeProperty: #foo ifAbsent: [false])
    ]

    testSeparatedBy [
	<category: 'testing'>
	| parser |
	parser := $a asParser separatedBy: $b asParser.
	self 
	    assert: parser
	    parse: 'a'
	    to: #($a).
	self 
	    assert: parser
	    parse: 'aba'
	    to: #($a $b $a).
	self 
	    assert: parser
	    parse: 'ababa'
	    to: #($a $b $a $b $a).
	self 
	    assert: parser
	    parse: 'ab'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'abab'
	    to: #($a $b $a)
	    end: 3.
	self 
	    assert: parser
	    parse: 'ac'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'abac'
	    to: #($a $b $a)
	    end: 3.
	self assert: parser fail: ''.
	self assert: parser fail: 'c'
    ]

    testSequence [
	<category: 'testing'>
	| parser |
	parser := $a asParser , $b asParser.
	self 
	    assert: parser
	    parse: 'ab'
	    to: #($a $b).
	self 
	    assert: parser
	    parse: 'aba'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abb'
	    to: #($a $b)
	    end: 2.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'aa'.
	self assert: parser fail: 'ba'.
	self assert: parser fail: 'bab'
    ]

    testSideEffectChoice [
	"Adding another element to a choice should create a copy, otherwise we get unwanted side-effects."

	<category: 'testing-fixtures'>
	| p1 p2 p3 |
	p1 := $a asParser.
	p2 := p1 / $b asParser.
	p3 := p1 / $c asParser.
	self assert: p1 parse: 'a'.
	self assert: p1 fail: 'b'.
	self assert: p1 fail: 'c'.
	self assert: p2 parse: 'a'.
	self assert: p2 parse: 'b'.
	self assert: p2 fail: 'c'.
	self assert: p3 parse: 'a'.
	self assert: p3 fail: 'b'.
	self assert: p3 parse: 'c'
    ]

    testSideEffectListCopy [
	<category: 'testing-fixtures'>
	| old new |
	old := $a asParser , $b asParser.
	new := old copy.
	self deny: old == new.
	self deny: old children == new children.
	self assert: old children first == new children first.
	self assert: old children last == new children last
    ]

    testSideEffectSequence [
	"Adding another element to a sequence should create a copy, otherwise we get unwanted side-effects."

	<category: 'testing-fixtures'>
	| p1 p2 p3 |
	p1 := $a asParser.
	p2 := p1 , $b asParser.
	p3 := p1 , $c asParser.
	self assert: p1 parse: 'a'.
	self 
	    assert: p1
	    parse: 'ab'
	    end: 1.
	self 
	    assert: p1
	    parse: 'ac'
	    end: 1.
	self assert: p2 fail: 'a'.
	self assert: p2 parse: 'ab'.
	self assert: p2 fail: 'ac'.
	self assert: p3 fail: 'a'.
	self assert: p3 fail: 'ab'.
	self assert: p3 parse: 'ac'
    ]

    testStar [
	<category: 'testing'>
	| parser |
	parser := $a asParser star.
	self assert: parser min = 0.
	self assert: parser max > parser min.
	self 
	    assert: parser
	    parse: ''
	    to: #().
	self 
	    assert: parser
	    parse: 'a'
	    to: #($a).
	self 
	    assert: parser
	    parse: 'aa'
	    to: #($a $a).
	self 
	    assert: parser
	    parse: 'aaa'
	    to: #($a $a $a).
	self 
	    assert: parser
	    parse: 'b'
	    to: #()
	    end: 0.
	self 
	    assert: parser
	    parse: 'ab'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'aab'
	    to: #($a $a)
	    end: 2.
	self 
	    assert: parser
	    parse: 'aaab'
	    to: #($a $a $a)
	    end: 3
    ]

    testStarGreedy [
	<category: 'testing'>
	| parser |
	parser := #word asParser starGreedy: #digit asParser.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'ab'.
	self 
	    assert: parser
	    parse: '1'
	    to: #()
	    end: 0.
	self 
	    assert: parser
	    parse: 'a1'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab1'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abc1'
	    to: #($a $b $c)
	    end: 3.
	self 
	    assert: parser
	    parse: '12'
	    to: #($1)
	    end: 1.
	self 
	    assert: parser
	    parse: 'a12'
	    to: #($a $1)
	    end: 2.
	self 
	    assert: parser
	    parse: 'ab12'
	    to: #($a $b $1)
	    end: 3.
	self 
	    assert: parser
	    parse: 'abc12'
	    to: #($a $b $c $1)
	    end: 4.
	self 
	    assert: parser
	    parse: '123'
	    to: #($1 $2)
	    end: 2.
	self 
	    assert: parser
	    parse: 'a123'
	    to: #($a $1 $2)
	    end: 3.
	self 
	    assert: parser
	    parse: 'ab123'
	    to: #($a $b $1 $2)
	    end: 4.
	self 
	    assert: parser
	    parse: 'abc123'
	    to: #($a $b $c $1 $2)
	    end: 5
    ]

    testStarLazy [
	<category: 'testing'>
	| parser |
	parser := #word asParser starLazy: #digit asParser.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self assert: parser fail: 'ab'.
	self 
	    assert: parser
	    parse: '1'
	    to: #()
	    end: 0.
	self 
	    assert: parser
	    parse: 'a1'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab1'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abc1'
	    to: #($a $b $c)
	    end: 3.
	self 
	    assert: parser
	    parse: '12'
	    to: #()
	    end: 0.
	self 
	    assert: parser
	    parse: 'a12'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab12'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abc12'
	    to: #($a $b $c)
	    end: 3.
	self 
	    assert: parser
	    parse: '123'
	    to: #()
	    end: 0.
	self 
	    assert: parser
	    parse: 'a123'
	    to: #($a)
	    end: 1.
	self 
	    assert: parser
	    parse: 'ab123'
	    to: #($a $b)
	    end: 2.
	self 
	    assert: parser
	    parse: 'abc123'
	    to: #($a $b $c)
	    end: 3
    ]

    testToken [
	<category: 'testing'>
	| parser |
	parser := $a asParser token.
	self assert: parser tokenClass = PPToken.
	self 
	    assert: parser
	    parse: 'a'
	    toToken: 1
	    stop: 1.
	self assert: parser fail: 'b'.
	self assert: parser fail: ''.
	parser := $a asParser token: PPToken.
	self assert: parser tokenClass = PPToken.
	self 
	    assert: parser
	    parse: 'a'
	    toToken: 1
	    stop: 1.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'
    ]

    testTrim [
	<category: 'testing'>
	| parser |
	parser := $a asParser token trim.
	self assert: parser trim = parser.
	self 
	    assert: parser
	    parse: 'a'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a '
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a	'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a  '
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a 
	 '
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: ' a'
	    toToken: 2
	    stop: 2.
	self 
	    assert: parser
	    parse: '	a'
	    toToken: 2
	    stop: 2.
	self 
	    assert: parser
	    parse: '    a'
	    toToken: 5
	    stop: 5.
	self 
	    assert: parser
	    parse: '   
a'
	    toToken: 5
	    stop: 5.
	self 
	    assert: parser
	    parse: 'aa'
	    toToken: 1
	    stop: 1
	    end: 1.
	self 
	    assert: parser
	    parse: 'a	a'
	    toToken: 1
	    stop: 1
	    end: 2.
	self 
	    assert: parser
	    parse: 'a  a'
	    toToken: 1
	    stop: 1
	    end: 3.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'
    ]

    testTrimBlanks [
	<category: 'testing'>
	| parser |
	parser := $a asParser token trimBlanks.
	self 
	    assert: parser
	    parse: 'a'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a '
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a	'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a  '
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: ' a'
	    toToken: 2
	    stop: 2.
	self 
	    assert: parser
	    parse: '	a'
	    toToken: 2
	    stop: 2.
	self 
	    assert: parser
	    parse: '    a'
	    toToken: 5
	    stop: 5.
	self 
	    assert: parser
	    parse: 'aa'
	    toToken: 1
	    stop: 1
	    end: 1.
	self 
	    assert: parser
	    parse: 'a	a'
	    toToken: 1
	    stop: 1
	    end: 2.
	self 
	    assert: parser
	    parse: 'a  a'
	    toToken: 1
	    stop: 1
	    end: 3.
	self assert: parser fail: ''.
	self assert: parser fail: '
'.
	self assert: parser fail: '
a'.
	self assert: parser fail: 'b'
    ]

    testTrimSpaces [
	<category: 'testing'>
	| parser |
	parser := $a asParser token trimSpaces.
	self 
	    assert: parser
	    parse: 'a'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a '
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a	'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a  '
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a 
	 '
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: 'a'
	    toToken: 1
	    stop: 1.
	self 
	    assert: parser
	    parse: ' a'
	    toToken: 2
	    stop: 2.
	self 
	    assert: parser
	    parse: '	a'
	    toToken: 2
	    stop: 2.
	self 
	    assert: parser
	    parse: '    a'
	    toToken: 5
	    stop: 5.
	self 
	    assert: parser
	    parse: '   
a'
	    toToken: 5
	    stop: 5.
	self 
	    assert: parser
	    parse: 'aa'
	    toToken: 1
	    stop: 1
	    end: 1.
	self 
	    assert: parser
	    parse: 'a	a'
	    toToken: 1
	    stop: 1
	    end: 2.
	self 
	    assert: parser
	    parse: 'a  a'
	    toToken: 1
	    stop: 1
	    end: 3.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'
    ]

    testUnresolved [
	<category: 'testing'>
	| parser |
	parser := PPUnresolvedParser new.
	self assert: parser isUnresolved.
	self should: [parser parse: ''] raise: Error.
	self should: [parser parse: 'a'] raise: Error.
	self should: [parser parse: 'ab'] raise: Error.
	parser := nil asParser.
	self deny: parser isUnresolved
    ]

    testWrapped [
	<category: 'testing'>
	| parser |
	parser := $a asParser wrapped.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self assert: parser fail: 'b'.
	parser := ($a asParser , $b asParser) wrapped , $c asParser.
	self 
	    assert: parser
	    parse: 'abc'
	    to: #(#($a $b) $c)
    ]

    testWrapping [
	<category: 'testing'>
	| parser result |
	parser := #digit asParser plus >=> 
			[:stream :cc | 
			Array 
			    with: stream position
			    with: cc value
			    with: stream position].
	self 
	    assert: parser
	    parse: '1'
	    to: #(0 #($1) 1).
	self 
	    assert: parser
	    parse: '12'
	    to: #(0 #($1 $2) 2).
	self 
	    assert: parser
	    parse: '123'
	    to: #(0 #($1 $2 $3) 3).
	result := parser parse: 'a'.
	self assert: result first = 0.
	self assert: result second isPetitFailure.
	self assert: result last = 0
    ]

    testXor [
	<category: 'testing'>
	| parser |
	parser := $a asParser / $b asParser | ($b asParser / $c asParser).
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'c'
	    to: $c.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'.
	self assert: parser fail: 'd'.

	"truly symmetric"
	parser := $b asParser / $c asParser | ($a asParser / $b asParser).
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'c'
	    to: $c.
	self assert: parser fail: ''.
	self assert: parser fail: 'b'.
	self assert: parser fail: 'd'
    ]
]



PPAbstractParseTest subclass: PPPredicateTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    assertCharacterSets: aParser [
	"Assert the character set of aParser does not overlap with the character set with the negated parser, and that they both cover the complete character space."

	<category: 'utilities'>
	| positives negatives |
	positives := self parsedCharacterSet: aParser.
	negatives := self parsedCharacterSet: aParser negate.
	self charactersDo: 
		[:char | 
		| positive negative |
		positive := positives includes: char.
		negative := negatives includes: char.
		self 
		    assert: ((positive and: [negative not]) or: [positive not and: [negative]])
		    description: char printString , ' should be in exactly one set']
    ]

    charactersDo: aBlock [
	<category: 'private'>
	1 to: 256 do: [:index | aBlock value: (Character codePoint: index)]
    ]

    parsedCharacterSet: aParser [
	<category: 'utilities'>
	| result |
	result := WriteStream on: String new.
	self charactersDo: 
		[:char | 
		(aParser matches: (String with: char)) ifTrue: [result nextPut: char]].
	^result contents
    ]

    testAny [
	<category: 'testing-objects'>
	| parser |
	parser := #any asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: ' '
	    to: $ .
	self 
	    assert: parser
	    parse: '1'
	    to: $1.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self assert: parser fail: ''
    ]

    testAnyExceptAnyOf [
	<category: 'testing-objects'>
	| parser |
	parser := PPPredicateObjectParser anyExceptAnyOf: #($: $,).
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'z'
	    to: $z.
	self assert: parser fail: ':'.
	self assert: parser fail: ','
    ]

    testAnyOf [
	<category: 'testing-objects'>
	| parser |
	parser := PPPredicateObjectParser anyOf: #($a $z).
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'z'
	    to: $z.
	self assert: parser fail: 'x'
    ]

    testBetweenAnd [
	<category: 'testing-objects'>
	| parser |
	parser := PPPredicateObjectParser between: $b and: $d.
	self assertCharacterSets: parser.
	self assert: parser fail: 'a'.
	self 
	    assert: parser
	    parse: 'b'
	    to: $b.
	self 
	    assert: parser
	    parse: 'c'
	    to: $c.
	self 
	    assert: parser
	    parse: 'd'
	    to: $d.
	self assert: parser fail: 'e'
    ]

    testBlank [
	<category: 'testing-chars'>
	| parser |
	parser := #blank asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: (String with: Character space)
	    to: Character space.
	self 
	    assert: parser
	    parse: (String with: Character tab)
	    to: Character tab.
	self assert: parser fail: ''.
	self assert: parser fail: '1'.
	self assert: parser fail: (String with: Character cr)
    ]

    testChar [
	<category: 'testing-chars'>
	| parser |
	parser := $* asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: '*'
	    to: $*.
	self 
	    assert: parser
	    parse: '**'
	    to: $*
	    end: 1.
	self assert: parser fail: ''.
	self assert: parser fail: '1'.
	self assert: parser fail: 'a'
    ]

    testControl [
	<category: 'testing-chars'>
	| parser |
	parser := #control asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: (String with: Character cr)
	    to: Character cr.
	self 
	    assert: parser
	    parse: (String with: Character tab)
	    to: Character tab.
	self assert: parser fail: ''.
	self assert: parser fail: '1'.
	self assert: parser fail: 'a'
    ]

    testCr [
	<category: 'testing-chars'>
	| parser |
	parser := #cr asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: (String with: Character cr)
	    to: Character cr
    ]

    testDigit [
	<category: 'testing-chars'>
	| parser |
	parser := #digit asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: '0'
	    to: $0.
	self 
	    assert: parser
	    parse: '9'
	    to: $9.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'
    ]

    testExpect [
	<category: 'testing-objects'>
	| parser |
	parser := PPPredicateObjectParser expect: $a.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self assert: parser fail: 'b'.
	self assert: parser fail: ''
    ]

    testHex [
	<category: 'testing-chars'>
	| parser |
	parser := #hex asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: '0'
	    to: $0.
	self 
	    assert: parser
	    parse: '5'
	    to: $5.
	self 
	    assert: parser
	    parse: '9'
	    to: $9.
	self 
	    assert: parser
	    parse: 'A'
	    to: $A.
	self 
	    assert: parser
	    parse: 'D'
	    to: $D.
	self 
	    assert: parser
	    parse: 'F'
	    to: $F.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'e'
	    to: $e.
	self 
	    assert: parser
	    parse: 'f'
	    to: $f.
	self assert: parser fail: ''.
	self assert: parser fail: 'g'
    ]

    testLetter [
	<category: 'testing-chars'>
	| parser |
	parser := #letter asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'Z'
	    to: $Z.
	self assert: parser fail: ''.
	self assert: parser fail: '0'
    ]

    testLf [
	<category: 'testing-chars'>
	| parser |
	parser := #lf asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: (String with: Character lf)
	    to: Character lf
    ]

    testLowercase [
	<category: 'testing-chars'>
	| parser |
	parser := #lowercase asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'z'
	    to: $z.
	self assert: parser fail: ''.
	self assert: parser fail: 'A'.
	self assert: parser fail: '0'
    ]

    testNewline [
	<category: 'testing-chars'>
	| parser |
	parser := #newline asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: (String with: Character cr)
	    to: Character cr.
	self 
	    assert: parser
	    parse: (String with: Character lf)
	    to: Character lf.
	self assert: parser fail: ' '
    ]

    testOnMessage [
	<category: 'testing'>
	| block parser |
	block := [:char | char = $*].
	parser := PPPredicateObjectParser on: block message: 'starlet'.
	self assert: parser block = block.
	self assert: parser message = 'starlet'.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: '*'
	    to: $*.
	self 
	    assert: parser
	    parse: '**'
	    to: $*
	    end: 1.
	self assert: parser fail: ''.
	self assert: parser fail: '1'.
	self assert: parser fail: 'a'
    ]

    testPunctuation [
	<category: 'testing-chars'>
	| parser |
	parser := #punctuation asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: '.'
	    to: $..
	self 
	    assert: parser
	    parse: ','
	    to: $,.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self assert: parser fail: '1'
    ]

    testSequenceParser [
	<category: 'testing-sequence'>
	| parser |
	parser := PPPredicateSequenceParser 
		    on: [:value | value first isUppercase]
		    message: 'uppercase 3 letter words'
		    size: 3.
	self assert: parser size = 3.
	self assert: parser parse: 'Abc'.
	self assert: parser parse: 'ABc'.
	self assert: parser parse: 'ABC'.
	self assert: parser fail: 'abc'.
	self assert: parser fail: 'aBC'.
	self assert: parser fail: 'Ab'.
	parser := parser negate.
	self assert: parser size = 3.
	self assert: parser fail: 'Abc'.
	self assert: parser fail: 'ABc'.
	self assert: parser fail: 'ABC'.
	self assert: parser parse: 'abc'.
	self assert: parser parse: 'aBC'.
	self assert: parser fail: 'Ab'
    ]

    testSpace [
	<category: 'testing-chars'>
	| parser |
	parser := #space asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: (String with: Character tab)
	    to: Character tab.
	self 
	    assert: parser
	    parse: ' '
	    to: Character space.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'
    ]

    testTab [
	<category: 'testing-chars'>
	| parser |
	parser := #tab asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: (String with: Character tab)
	    to: Character tab
    ]

    testUppercase [
	<category: 'testing-chars'>
	| parser |
	parser := #uppercase asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: 'A'
	    to: $A.
	self 
	    assert: parser
	    parse: 'Z'
	    to: $Z.
	self assert: parser fail: ''.
	self assert: parser fail: 'a'.
	self assert: parser fail: '0'
    ]

    testWord [
	<category: 'testing-chars'>
	| parser |
	parser := #word asParser.
	self assertCharacterSets: parser.
	self 
	    assert: parser
	    parse: 'a'
	    to: $a.
	self 
	    assert: parser
	    parse: 'A'
	    to: $A.
	self 
	    assert: parser
	    parse: '0'
	    to: $0.
	self assert: parser fail: ''.
	self assert: parser fail: '-'
    ]
]



PPAbstractParseTest subclass: PPScriptingTest [
    
    <comment: 'These are some simple demo-scripts of parser combinators for the compiler construction course.http://www.iam.unibe.ch/~scg/Teaching/CC/index.html'>
    <category: 'PetitTests-Tests'>

    expressionInterpreter [
	"Same as #expressionInterpreter but with semantic actions."

	<category: 'examples'>
	| mul prim add dec |
	add := PPUnresolvedParser new.
	mul := PPUnresolvedParser new.
	prim := PPUnresolvedParser new.
	dec := $0 - $9 ==> [:token | token codePoint - $0 codePoint].
	add 
	    def: ((mul , $+ asParser , add) 
		    ==> [:nodes | (nodes at: 1) + (nodes at: 3)]) / mul.
	mul 
	    def: ((prim , $* asParser , mul) 
		    ==> [:nodes | (nodes at: 1) * (nodes at: 3)]) / prim.
	prim 
	    def: (($( asParser , add , $) asParser) ==> [:nodes | nodes at: 2]) / dec.
	^add end
    ]

    expressionParser [
	"Simple demo of scripting an expression parser."

	<category: 'examples'>
	| mul prim add dec |
	add := PPUnresolvedParser new.
	mul := PPUnresolvedParser new.
	prim := PPUnresolvedParser new.
	dec := $0 - $9.
	add def: (mul , $+ asParser , add) / mul.
	mul def: (prim , $* asParser , mul) / prim.
	prim def: ($( asParser , add , $) asParser) / dec.
	^add end
    ]

    straightLineParser [
	<category: 'examples'>
	| goal stm stmList id char dec exp expList mulExp primExp nonzero num lower upper |
	goal := PPUnresolvedParser new.
	stmList := PPUnresolvedParser new.
	stm := PPUnresolvedParser new.
	exp := PPUnresolvedParser new.
	expList := PPUnresolvedParser new.
	mulExp := PPUnresolvedParser new.
	primExp := PPUnresolvedParser new.
	lower := $a - $z.
	upper := $A - $Z.
	char := lower / upper.
	nonzero := $1 - $9.
	dec := $0 - $9.
	id := char , (char / dec) star.
	num := $0 asParser / (nonzero , dec star).
	goal def: stmList end.
	stmList def: stm , ($; asParser , stm) star.
	stm def: (id , ':=' asParser , exp) 
		    / ('print' asParser , $( asParser , expList , $) asParser).
	exp def: mulExp , ($+ asParser / $- asParser , mulExp) star.
	expList def: exp , ($, asParser , exp) star.
	mulExp def: primExp , ($* asParser / $/ asParser , primExp) star.
	primExp 
	    def: id / num / ($( asParser , stmList , $, asParser , exp , $) asParser).
	^goal
    ]

    testExpressionInterpreter [
	<category: 'tests'>
	self 
	    assert: self expressionInterpreter
	    parse: '2*(3+4)'
	    to: 14
    ]

    testExpressionParser [
	<category: 'tests'>
	self 
	    assert: self expressionParser
	    parse: '2*(3+4)'
	    to: #($2 $* #($( #($3 $+ $4) $)))
    ]

    testSLassign [
	<category: 'tests'>
	self 
	    assert: self straightLineParser
	    parse: 'abc:=1'
	    to: #(#($a #($b $c) ':=' #(#(#($1 #()) #()) #())) #())
    ]

    testSLprint [
	<category: 'tests'>
	self 
	    assert: self straightLineParser
	    parse: 'print(3,4)'
	    to: #(#('print' $( #(#(#($3 #()) #()) #() #(#($, #(#(#($4 #()) #()) #())))) $)) #())
    ]
]



PPAbstractParseTest subclass: PPTokenTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    identifier [
	<category: 'accessing'>
	^#word asParser plus token
    ]

    parse: aString using: aParser [
	<category: 'utilities'>
	^aParser parse: aString
    ]

    testCollection [
	<category: 'testing'>
	| input result |
	input := 'foo    '.
	result := self parse: input using: self identifier.
	self assert: result collection = input.
	self assert: result collection == input
    ]

    testColumn [
	<category: 'testing-querying'>
	| input parser result |
	input := '1' , (String with: Character cr) , '12' 
		    , (String with: Character cr with: Character lf) , '123' 
		    , (String with: Character lf) , '1234'.
	parser := #any asParser token star.
	result := parser parse: input.
	result with: #(1 2 1 2 3 4 1 2 3 4 1 2 3 4)
	    do: [:token :line | self assert: token column = line]
    ]

    testCopyFromTo [
	<category: 'testing-copying'>
	| result other |
	result := PPToken on: 'abc'.
	other := result copyFrom: 2 to: 2.
	self assert: other size = 1.
	self assert: other start = 2.
	self assert: other stop = 2.
	self assert: other collection = result collection
    ]

    testEquality [
	<category: 'testing-comparing'>
	| token1 token2 |
	token1 := self parse: 'foo' using: self identifier.
	token2 := self parse: 'foo' using: self identifier.
	self deny: token1 == token2.
	self assert: token1 = token2.
	self assert: token1 hash = token2 hash
    ]

    testLine [
	<category: 'testing-querying'>
	| input parser result |
	input := '1' , (String with: Character cr) , '12' 
		    , (String with: Character cr with: Character lf) , '123' 
		    , (String with: Character lf) , '1234'.
	parser := #any asParser token star.
	result := parser parse: input.
	result with: #(1 1 2 2 2 2 3 3 3 3 4 4 4 4)
	    do: [:token :line | self assert: token line = line]
    ]

    testNew [
	<category: 'testing'>
	self should: [PPToken new] raise: Error
    ]

    testPrinting [
	<category: 'testing'>
	| result |
	result := PPToken on: 'var'.
	self assert: result printString = 'a PPToken(var)'
    ]

    testSize [
	<category: 'testing'>
	| result |
	result := self parse: 'foo' using: self identifier.
	self assert: result size = 3
    ]

    testStart [
	<category: 'testing'>
	| result |
	result := self parse: 'foo' using: self identifier.
	self assert: result start = 1
    ]

    testStop [
	<category: 'testing'>
	| result |
	result := self parse: 'foo' using: self identifier.
	self assert: result stop = 3
    ]

    testValue [
	<category: 'testing'>
	| input result |
	input := 'foo'.
	result := self parse: input using: self identifier.
	self assert: result value = input.
	self deny: result value == input
    ]
]



TestCase subclass: PPCompositeParserTest [
    | parser |
    
    <comment: nil>
    <category: 'PetitTests-Core'>

    PPCompositeParserTest class >> isAbstract [
	<category: 'testing'>
	^self name = #PPCompositeParserTest
    ]

    PPCompositeParserTest class >> resources [
	<category: 'accessing'>
	^Array with: PPParserResource
    ]

    assert: aCollection is: anObject [
	<category: 'utilities'>
	| result |
	result := parser parse: aCollection onError: [:err :pos | self error: err].
	self 
	    assert: result = anObject
	    description: 'Got: ' , result printString , '; Expected: ' 
		    , anObject printString
	    resumable: true
    ]

    parserClass [
	<category: 'accessing'>
	self subclassResponsibility
    ]

    parserInstance [
	<category: 'accessing'>
	^PPParserResource current parserAt: self parserClass
    ]

    setUp [
	<category: 'running'>
	super setUp.
	parser := self parserInstance
    ]
]



PPCompositeParserTest subclass: PPArithmeticParserTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    parserClass [
	<category: 'accessing'>
	^PPArithmeticParser
    ]

    testAdd [
	<category: 'testing-operations'>
	self assert: '1 + 2' is: 3.
	self assert: '2 + 1' is: 3.
	self assert: '1 + 2.3' is: 3.3.
	self assert: '2.3 + 1' is: 3.3.
	self assert: '1 + -2' is: -1.
	self assert: '-2 + 1' is: -1
    ]

    testAddMany [
	<category: 'testing-operations'>
	self assert: '1' is: 1.
	self assert: '1 + 2' is: 3.
	self assert: '1 + 2 + 3' is: 6.
	self assert: '1 + 2 + 3 + 4' is: 10.
	self assert: '1 + 2 + 3 + 4 + 5' is: 15
    ]

    testBrackets [
	<category: 'testing-expression'>
	self assert: '(1)' is: 1.
	self assert: '(1 + 2)' is: 3.
	self assert: '((1))' is: 1.
	self assert: '((1 + 2))' is: 3.
	self assert: '2 * (3 + 4)' is: 14.
	self assert: '(2 + 3) * 4' is: 20.
	self assert: '6 / (2 + 4)' is: 1.
	self assert: '(2 + 6) / 2' is: 4
    ]

    testDiv [
	<category: 'testing-operations'>
	self assert: '12 / 3' is: 4.
	self assert: '-16 / -4' is: 4
    ]

    testDivMany [
	<category: 'testing-operations'>
	self assert: '100 / 2' is: 50.
	self assert: '100 / 2 / 2' is: 25.
	self assert: '100 / 2 / 2 / 5' is: 5.
	self assert: '100 / 2 / 2 / 5 / 5' is: 1
    ]

    testMul [
	<category: 'testing-operations'>
	self assert: '2 * 3' is: 6.
	self assert: '2 * -4' is: -8
    ]

    testMulMany [
	<category: 'testing-operations'>
	self assert: '1 * 2' is: 2.
	self assert: '1 * 2 * 3' is: 6.
	self assert: '1 * 2 * 3 * 4' is: 24.
	self assert: '1 * 2 * 3 * 4 * 5' is: 120
    ]

    testNum [
	<category: 'testing'>
	self assert: '0' is: 0.
	self assert: '0.0' is: 0.0.
	self assert: '1' is: 1.
	self assert: '1.2' is: 1.2.
	self assert: '34' is: 34.
	self assert: '56.78' is: 56.78.
	self assert: '-9' is: -9.
	self assert: '-9.9' is: -9.9
    ]

    testPow [
	<category: 'testing-operations'>
	self assert: '2 ^ 3' is: 8.
	self assert: '-2 ^ 3' is: -8.
	self assert: '-2 ^ -3' is: -0.125
    ]

    testPowMany [
	<category: 'testing-operations'>
	self assert: '4 ^ 3' is: 64.
	self assert: '4 ^ 3 ^ 2' is: 262144.
	self assert: '4 ^ 3 ^ 2 ^ 1' is: 262144.
	self assert: '4 ^ 3 ^ 2 ^ 1 ^ 0' is: 262144
    ]

    testPriority [
	<category: 'testing-expression'>
	self assert: '2 * 3 + 4' is: 10.
	self assert: '2 + 3 * 4' is: 14.
	self assert: '6 / 3 + 4' is: 6.
	self assert: '2 + 6 / 2' is: 5
    ]

    testSub [
	<category: 'testing-operations'>
	self assert: '1 - 2' is: -1.
	self assert: '1.3 - 2' is: -0.7000000000000001.
	self assert: '1 - -2' is: 3.
	self assert: '-1 - -2' is: 1
    ]

    testSubMany [
	<category: 'testing-operations'>
	self assert: '1' is: 1.
	self assert: '1 - 2' is: -1.
	self assert: '1 - 2 - 3' is: -4.
	self assert: '1 - 2 - 3 - 4' is: -8.
	self assert: '1 - 2 - 3 - 4 - 5' is: -13
    ]
]



PPArithmeticParserTest subclass: PPExpressionParserTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    PPExpressionParserTest class >> shouldInheritSelectors [
	<category: 'testing'>
	^true
    ]

    parserInstance [
	<category: 'accessing'>
	| expression parens number |
	expression := PPExpressionParser new.
	parens := ($( asParser token trim , expression , $) asParser token trim) 
		    ==> [:nodes | nodes second].
	number := (#digit asParser plus 
		    , ($. asParser , #digit asParser plus) optional) token 
		    trim ==> [:token | token value asNumber].
	expression term: parens / number.
	expression
	    group: [:g | g prefix: $- asParser token trim do: [:op :a | a negated]];
	    group: 
		    [:g | 
		    g postfix: '++' asParser token trim do: [:a :op | a + 1].
		    g postfix: '--' asParser token trim do: [:a :op | a - 1]];
	    group: [:g | g right: $^ asParser token trim do: [:a :op :b | a raisedTo: b]];
	    group: 
		    [:g | 
		    g left: $* asParser token trim do: [:a :op :b | a * b].
		    g left: $/ asParser token trim do: [:a :op :b | a / b]];
	    group: 
		    [:g | 
		    g left: $+ asParser token trim do: [:a :op :b | a + b].
		    g left: $- asParser token trim do: [:a :op :b | a - b]].
	^expression end
    ]

    testPostfixAdd [
	<category: 'testing'>
	self assert: '0++' is: 1.
	self assert: '0++++' is: 2.
	self assert: '0++++++' is: 3.
	self assert: '0+++1' is: 2.
	self assert: '0+++++1' is: 3.
	self assert: '0+++++++1' is: 4
    ]

    testPostfixSub [
	<category: 'testing'>
	self assert: '1--' is: 0.
	self assert: '2----' is: 0.
	self assert: '3------' is: 0.
	self assert: '2---1' is: 0.
	self assert: '3-----1' is: 0.
	self assert: '4-------1' is: 0
    ]

    testPrefixNegate [
	<category: 'testing'>
	self assert: '1' is: 1.
	self assert: '-1' is: -1.
	self assert: '--1' is: 1.
	self assert: '---1' is: -1
    ]
]



PPCompositeParserTest subclass: PPLambdaParserTest [
    
    <comment: nil>
    <category: 'PetitTests-Tests'>

    parserClass [
	<category: 'accessing'>
	^PPLambdaParser
    ]

    testAbstraction [
	<category: 'testing'>
	self assert: '\x.y' is: #('x' 'y').
	self assert: '\x.\y.z' is: #('x' #('y' 'z'))
    ]

    testAnd [
	<category: 'testing-curch'>
	self assert: self parserClass and = #('p' #('q' #(#('p' 'q') 'p')))
    ]

    testApplication [
	<category: 'testing'>
	self assert: '(x x)' is: #('x' 'x').
	self assert: '(x y)' is: #('x' 'y').
	self assert: '((x y) z)' is: #(#('x' 'y') 'z').
	self assert: '(x (y z))' is: #('x' #('y' 'z'))
    ]

    testFalse [
	<category: 'testing-curch'>
	self assert: self parserClass false = #('x' #('y' 'y'))
    ]

    testIfThenElse [
	<category: 'testing-curch'>
	self assert: self parserClass ifthenelse = #('p' 'p')
    ]

    testNot [
	<category: 'testing-curch'>
	self assert: self parserClass not = #('p' #('a' #('b' #(#('p' 'b') 'a'))))
    ]

    testOr [
	<category: 'testing-curch'>
	self assert: self parserClass or = #('p' #('q' #(#('p' 'p') 'q')))
    ]

    testParseOnError [
	<category: 'testing-utilities'>
	| result beenHere |
	result := self parserClass parse: '\x.y' onError: [self fail].
	self assert: result = #('x' 'y').
	beenHere := false.
	result := self parserClass parse: '\x.' onError: [beenHere := true].
	self assert: beenHere.
	beenHere := false.
	result := self parserClass parse: '\x.'
		    onError: 
			[:fail | 
			beenHere := true.
			fail].
	self assert: beenHere.
	self assert: result message = '$( expected'.
	self assert: result position = 0.
	beenHere := false.
	result := self parserClass parse: '\x.'
		    onError: 
			[:msg :pos | 
			self assert: msg = '$( expected'.
			self assert: pos = 0.
			beenHere := true].
	self assert: result.
	self assert: beenHere
    ]

    testParseStartingAtOnError [
	<category: 'testing-utilities'>
	| result beenHere |
	result := self parserClass 
		    parse: 'x'
		    startingAt: #variable
		    onError: [self fail].
	self assert: result = 'x'.
	beenHere := false.
	result := self parserClass 
		    parse: '\'
		    startingAt: #variable
		    onError: [beenHere := true].
	self assert: beenHere.
	beenHere := false.
	result := self parserClass 
		    parse: '\'
		    startingAt: #variable
		    onError: 
			[:fail | 
			beenHere := true.
			fail].
	self assert: beenHere.
	self assert: result message = 'letter expected'.
	self assert: result position = 0.
	beenHere := false.
	result := self parserClass 
		    parse: '\'
		    startingAt: #variable
		    onError: 
			[:msg :pos | 
			self assert: msg = 'letter expected'.
			self assert: pos = 0.
			beenHere := true].
	self assert: beenHere
    ]

    testProductionAt [
	<category: 'testing-utilities'>
	self assert: (parser productionAt: #foo) isNil.
	self assert: (parser productionAt: #foo ifAbsent: [true]).
	self assert: (parser productionAt: #start) notNil.
	self assert: (parser productionAt: #start ifAbsent: [true]) notNil.
	self assert: (parser productionAt: #variable) notNil.
	self assert: (parser productionAt: #variable ifAbsent: [true]) notNil
    ]

    testTrue [
	<category: 'testing-curch'>
	self assert: self parserClass true = #('x' #('y' 'x'))
    ]

    testVariable [
	<category: 'testing'>
	self assert: 'x' is: 'x'.
	self assert: 'xy' is: 'xy'.
	self assert: 'x12' is: 'x12'
    ]
]



PPCompositeParser subclass: PPArithmeticParser [
    | terms addition factors multiplication power primary parentheses number |
    
    <comment: nil>
    <category: 'PetitTests-Examples'>

    addition [
	<category: 'grammar'>
	^(factors separatedBy: ($+ asParser / $- asParser) token trim) 
	    foldLeft: [:a :op :b | a perform: op value asSymbol with: b]
    ]

    factors [
	<category: 'grammar'>
	^multiplication / power
    ]

    multiplication [
	<category: 'grammar'>
	^(power separatedBy: ($* asParser / $/ asParser) token trim) 
	    foldLeft: [:a :op :b | a perform: op value asSymbol with: b]
    ]

    number [
	<category: 'grammar'>
	^($- asParser optional , #digit asParser plus 
	    , ($. asParser , #digit asParser plus) optional) token 
	    trim ==> [:token | token value asNumber]
    ]

    parentheses [
	<category: 'grammar'>
	^($( asParser flatten trim , terms , $) asParser flatten trim) ==> #second
    ]

    power [
	<category: 'grammar'>
	^(primary separatedBy: $^ asParser token trim) 
	    foldRight: [:a :op :b | a raisedTo: b]
    ]

    primary [
	<category: 'grammar'>
	^number / parentheses
    ]

    start [
	<category: 'accessing'>
	^terms end
    ]

    terms [
	<category: 'grammar'>
	^addition / factors
    ]
]



PPCompositeParser subclass: PPLambdaParser [
    | expression abstraction application variable |
    
    <comment: nil>
    <category: 'PetitTests-Examples'>

    PPLambdaParser class >> and [
	<category: 'curch-booleans'>
	^self parse: '\p.\q.((p q) p)'
    ]

    PPLambdaParser class >> false [
	<category: 'curch-booleans'>
	^self parse: '\x.\y.y'
    ]

    PPLambdaParser class >> ifthenelse [
	<category: 'curch-booleans'>
	^self parse: '\p.p'
    ]

    PPLambdaParser class >> not [
	<category: 'curch-booleans'>
	^self parse: '\p.\a.\b.((p b) a)'
    ]

    PPLambdaParser class >> or [
	<category: 'curch-booleans'>
	^self parse: '\p.\q.((p p) q)'
    ]

    PPLambdaParser class >> true [
	<category: 'curch-booleans'>
	^self parse: '\x.\y.x'
    ]

    abstraction [
	<category: 'productions'>
	^($\ asParser token trim , variable , $. asParser token trim , expression) 
	    ==> [:node | Array with: node second with: node fourth]
    ]

    application [
	<category: 'productions'>
	^($( asParser token trim , expression , expression 
	    , $) asParser token trim) 
		==> [:node | Array with: node second with: node third]
    ]

    expression [
	<category: 'productions'>
	^variable / abstraction / application
    ]

    start [
	<category: 'accessing'>
	^expression end
    ]

    variable [
	<category: 'productions'>
	^(#letter asParser , #word asParser star) token trim 
	    ==> [:token | token value]
    ]
]

