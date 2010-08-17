String extend [

    asParser [
	<category: '*petitparser-core-converting'>
	^PPLiteralSequenceParser on: self
    ]

]



Stream extend [

    asPetitStream [
	<category: '*petitparser-core-converting'>
	^self contents asPetitStream
    ]

]



Symbol extend [

    asParser [
	<category: '*petitparser-core-converting'>
	^PPPredicateObjectParser perform: self
    ]

]



Set extend [

    asParser [
	<category: '*petitparser-core-converting'>
	^PPChoiceParser withAll: (self collect: [:each | each asParser])
    ]

]



BlockContext extend [

    asParser [
	<category: '*petitparser-core-converting'>
	^PPPluggableParser on: self
    ]

]



UndefinedObject extend [

    asParser [
	<category: '*petitparser-converting'>
	^PPEpsilonParser new
    ]

]



PositionableStream extend [

    asPetitStream [
	"Some of my subclasses do not use the instance-variables collection, position and readLimit but instead have a completely different internal representation. In these cases just use the super implementation that is inefficient but should work in all cases."

	<category: '*petitparser-core-converting'>
	^(collection isNil or: [position isNil or: [readLimit isNil]]) 
	    ifFalse: 
		[PPStream 
		    on: collection
		    from: position
		    to: readLimit]
	    ifTrue: [super asPetitStream]
    ]

    collection [
	<category: '*petitparser-core-accessing'>
	^collection
    ]

]



ReadStream subclass: PPStream [
    
    <category: 'PetitParser-Core'>
    <comment: 'A positional stream implementation used for parsing. It overrides some methods for optimization reasons.'>

    asPetitStream [
	<category: 'converting'>
	^self
    ]

    next: anInteger [
	"Answer up to anInteger elements of my collection. Overridden for efficiency."

	<category: 'accessing'>
	| answer endPosition |
	endPosition := position + anInteger min: readLimit.
	answer := collection copyFrom: position + 1 to: endPosition.
	position := endPosition.
	^answer
    ]

    peek [
	"An improved version of peek, that is slightly faster than the built in version."

	<category: 'accessing'>
	^self atEnd ifFalse: [collection at: position + 1]
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream
	    nextPutAll: (collection copyFrom: 1 to: position);
	    nextPutAll: '·';
	    nextPutAll: (collection copyFrom: position + 1 to: readLimit)
    ]
]



BlockClosure extend [

    asParser [
	<category: '*petitparser-core-converting'>
	^PPPluggableParser on: self
    ]

]



Character extend [

    - aCharacter [
	"Create a range of characters between the receiver and the argument."

	<category: '*petitparser-core-operators'>
	^PPPredicateObjectParser between: self and: aCharacter
    ]

    asParser [
	<category: '*petitparser-converting'>
	^PPLiteralObjectParser on: self
    ]

]



SequenceableCollection extend [

    asParser [
	<category: '*petitparser-core-converting'>
	^PPSequenceParser withAll: (self collect: [:each | each asParser])
    ]

    asPetitStream [
	<category: '*petitparser-core-converting'>
	^PPStream on: self
    ]

]



Object extend [

    asParser [
	<category: '*petitparser-core-converting'>
	^PPPredicateObjectParser expect: self
    ]

    isPetitFailure [
	<category: '*petitparser-core-testing'>
	^false
    ]

]



Object subclass: PPFailure [
    | message position |
    
    <category: 'PetitParser-Core'>
    <comment: 'The failure object in PetitParser. It is the only class that responds to #isPetitFailure with true. It contains an error message and a position of the occurrence of the failure.

Instance Variables:
	message	<String>	The error message of this failure.
	position	<Integer>	The position of this failure in the input stream.
'>

    PPFailure class >> message: aString at: anInteger [
	<category: 'instance creation'>
	^self basicNew initializeMessage: aString at: anInteger
    ]

    initializeMessage: aString at: anInteger [
	<category: 'initialization'>
	message := aString.
	position := anInteger
    ]

    isPetitFailure [
	"I am the only class that should implement this method to return true."

	<category: 'testing'>
	^true
    ]

    message [
	"Answer a human readable error message of this parse failure."

	<category: 'accessing'>
	^message
    ]

    position [
	"Answer the position in the source string that caused this parse failure."

	<category: 'accessing'>
	^position
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream
	    nextPutAll: self message;
	    nextPutAll: ' at ';
	    print: position
    ]
]



Object subclass: PPMemento [
    | result count position |
    
    <category: 'PetitParser-Core'>
    <comment: 'PPMemento is an internal class used by PPMemoizedParser to cache results and detect left-recursive calls.

Instance Variables:
	result	<Object>	The cached result.
	count	<Integer>	The number of recursive cycles followed.
	position	<Integer>	The position of the cached result in the input stream.'>

    PPMemento class >> new [
	<category: 'instance creation'>
	^self basicNew initialize
    ]

    count [
	<category: 'accessing-readonly'>
	^count
    ]

    increment [
	<category: 'actions'>
	count := count + 1
    ]

    initialize [
	<category: 'initialization'>
	count := 0
    ]

    position [
	<category: 'accessing'>
	^position
    ]

    position: anInteger [
	<category: 'accessing'>
	position := anInteger
    ]

    result [
	<category: 'accessing'>
	^result
    ]

    result: anObject [
	<category: 'accessing'>
	result := anObject
    ]
]



Object subclass: PPParser [
    | properties |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'An abstract parser for all parsers in PetitParser. Subclasses implement #parseOn: to perform the actual recursive-descent parsing. All parsers support a variety of methods to perform an actual parse, see the methods in the #parsing protocol. Parsers are combined with a series of operators that can be found in the #operations protocol.

Instance Variables:
	properties	<Dictionary>	Stores additional state in the parser object.'>

    PPParser class >> named: aString [
	<category: 'instance creation'>
	^self new name: aString
    ]

    PPParser class >> new [
	<category: 'instance creation'>
	^self basicNew initialize
    ]

    , aParser [
	"Answer a new parser that parses the receiver followed by aParser."

	<category: 'operations'>
	^PPSequenceParser with: self with: aParser
    ]

    / aParser [
	"Answer a new parser that parses the receiver, if the receiver fails try with aParser (ordered-choice)."

	<category: 'operations'>
	^PPChoiceParser with: self with: aParser
    ]

    ==> aBlock [
	"Answer a new parser that performs aBlock as action handler on success."

	<category: 'operations-mapping'>
	^PPActionParser on: self block: aBlock
    ]

    >=> aBlock [
	"Answer a new parser that wraps the receiving parser with a two argument block. The first argument is the parsed stream, the second argument a continuation block on the delegate parser."

	<category: 'operations-mapping'>
	^PPWrappingParser on: self block: aBlock
    ]

    and [
	"Answer a new parser (logical and-predicate) that succeeds whenever the receiver does, but never consumes input."

	<category: 'operations'>
	^PPAndParser on: self
    ]

    answer: anObject [
	"Answer a new parser that always returns anObject from a successful parse."

	<category: 'operations-mapping'>
	^self ==> [:nodes | anObject]
    ]

    asParser [
	<category: 'converting'>
	^self
    ]

    children [
	"Answer a set of child parsers that could follow the receiver."

	<category: 'accessing'>
	^#()
    ]

    def: aParser [
	"Redefine the receiver as the argument aParser. This method is useful when defining recursive parsers: instantiate a PPParser and later redefine it with another one."

	<category: 'operations'>
	^self becomeForward: (aParser name: self name)
    ]

    delimitedBy: aParser [
	"Answer a new parser that parses the receiver one or more times, separated and possibly ended by aParser."

	<category: 'operations-convenience'>
	^((self separatedBy: aParser) , aParser optional) ==> 
		[:node | 
		node second isNil 
		    ifTrue: [node first]
		    ifFalse: [node first copyWith: node second]]
    ]

    end [
	"Answer a new parser that succeeds at the end of the input and return the result of the receiver."

	<category: 'operations'>
	^PPEndOfInputParser on: self
    ]

    flatten [
	"Answer a new parser that flattens the underlying collection."

	<category: 'operations-mapping'>
	^PPFlattenParser on: self
    ]

    foldLeft: aBlock [
	"Answer a new parser that that folds the result of the receiver from left-to-right into aBlock. The argument aBlock must take two or more arguments."

	<category: 'operations-mapping'>
	| size args |
	size := aBlock numArgs.
	args := Array new: size.
	^self ==> 
		[:nodes | 
		args at: 1 put: (nodes at: 1).
		2 to: nodes size
		    by: size - 1
		    do: 
			[:index | 
			args
			    replaceFrom: 2
				to: size
				with: nodes
				startingAt: index;
			    at: 1 put: (aBlock valueWithArguments: args)].
		args at: 1]
    ]

    foldRight: aBlock [
	"Answer a new parser that that folds the result of the receiver from right-to-left into aBlock. The argument aBlock must take two or more arguments."

	<category: 'operations-mapping'>
	| size args |
	size := aBlock numArgs.
	args := Array new: size.
	^self ==> 
		[:nodes | 
		args at: size put: (nodes at: nodes size).
		nodes size - size + 1 to: 1
		    by: 1 - size
		    do: 
			[:index | 
			args
			    replaceFrom: 1
				to: size - 1
				with: nodes
				startingAt: index;
			    at: size put: (aBlock valueWithArguments: args)].
		args at: size]
    ]

    hasProperty: aKey [
	"Test if the property aKey is present."

	<category: 'accessing-properties'>
	^properties notNil and: [properties includesKey: aKey]
    ]

    initialize [
	<category: 'initialization'>
	
    ]

    isUnresolved [
	<category: 'testing'>
	^false
    ]

    map: aBlock [
	"Answer a new parser that works on the receiving sequence an passes in each element as a block argument."

	<category: 'operations-mapping'>
	^self ==> aBlock
    ]

    matches: anObject [
	"Answer if anObject can be parsed by the receiver."

	<category: 'parsing'>
	^(self parse: anObject) isPetitFailure not
    ]

    matchesIn: anObject [
	"Search anObject repeatedly for the matches of the receiver."

	<category: 'parsing'>
	| result |
	result := OrderedCollection new.
	self matchesIn: anObject do: [:each | result addLast: each].
	^result
    ]

    matchesIn: anObject do: aBlock [
	"Search anObject repeatedly for the matches of the receiver. Evaluate aBlock for each match with the matched parse-tree as the argument. Make sure to always consume exactly one character with each step, to not miss any match."

	<category: 'parsing'>
	((self and ==> aBlock , #any asParser) / #any asParser) star 
	    parse: anObject
    ]

    matchingRangesIn: anObject [
	"Search anObject repeatedly for the matches of the receiver.  Answer an OrderedCollection of ranges of each match (index of first character to: index of last character)."

	<category: 'parsing'>
	| result |
	result := OrderedCollection new.
	[:stream | stream position + 1] asParser , self 
	    , [:stream | stream position] asParser matchesIn: anObject
		do: [:value | result addLast: (value first to: value last)].
	^result
    ]

    max: anInteger [
	"Answer a new parser that parses the receiver at most anInteger times."

	<category: 'operations'>
	^PPRepeatingParser on: self max: anInteger
    ]

    memoized [
	"Answer a new memoized parser, for refraining redundant computations. This ensures polynomial time O(n^4) for left-recursive grammars and O(n^3) for non left-recursive grammars in the worst case. Not necessary for most grammars that are carefully written and in O(n) anyway."

	<category: 'operations'>
	^PPMemoizedParser on: self
    ]

    min: anInteger [
	"Answer a new parser that parses the receiver at least anInteger times."

	<category: 'operations'>
	^PPRepeatingParser on: self min: anInteger
    ]

    min: aMinInteger max: aMaxInteger [
	"Answer a new parser that parses the receiver at least aMinInteger and at most aMaxInteger times."

	<category: 'operations'>
	^PPRepeatingParser 
	    on: self
	    min: aMinInteger
	    max: aMaxInteger
    ]

    name [
	"Answer the production name of the receiver."

	<category: 'accessing'>
	^self propertyAt: #name ifAbsent: [nil]
    ]

    name: aString [
	<category: 'accessing'>
	self propertyAt: #name put: aString
    ]

    negate [
	"Answer a new parser consumes any input token but the receiver."

	<category: 'operations'>
	^(self not , #any asParser) ==> #second
    ]

    not [
	"Answer a new parser (logical not-predicate) that succeeds whenever the receiver fails, but never consumes input."

	<category: 'operations'>
	^PPNotParser on: self
    ]

    optional [
	"Answer a new parser that parses the receiver, if possible."

	<category: 'operations'>
	^self / nil asParser
    ]

    parse: anObject [
	"Parse anObject with the receiving parser and answer the parse-result or an instance of PPFailure."

	<category: 'parsing'>
	^self parseOn: anObject asPetitStream
    ]

    parse: anObject onError: aBlock [
	"Parse anObject with the receiving parser and answer the parse-result or answer the result of evaluating aBlock. Depending on the number of arguments of the block it is simply evaluated, evaluated with the failure object, or evaluated with the error message and position."

	<category: 'parsing'>
	| result |
	result := self parseOn: anObject asPetitStream.
	result isPetitFailure ifFalse: [^result].
	aBlock numArgs = 0 ifTrue: [^aBlock value].
	aBlock numArgs = 1 ifTrue: [^aBlock value: result].
	^aBlock value: result message value: result position
    ]

    parseOn: aStream [
	"Parse aStream with the receiving parser and answer the parse-result or an instance of PPFailure. Override this method in subclasses to specify custom parse behavior. Do not call this method from outside, instead use #parse:."

	<category: 'parsing'>
	self subclassResponsibility
    ]

    plus [
	"Answer a new parser that parses the receiver one or more times."

	<category: 'operations'>
	^self min: 1
    ]

    plusGreedy: aParser [
	"Answer a new parser that parses the receiver one or more times until it reaches aParser. This is a greedy non-blind implementation of the star operator. aParser is not consumed."

	<category: 'operations'>
	^self , (self starGreedy: aParser) 
	    map: [:first :rest | rest copyWithFirst: first]
    ]

    plusLazy: aParser [
	"Answer a new parser that parses the receiver one or more times until it reaches aParser. This is a lazy non-blind implementation of the star operator. aParser is not consumed."

	<category: 'operations'>
	^self , (self starLazy: aParser) 
	    map: [:first :rest | rest copyWithFirst: first]
    ]

    postCopy [
	<category: 'copying'>
	super postCopy.
	properties := properties copy
    ]

    printNameOn: aStream [
	<category: 'printing'>
	self name isNil 
	    ifTrue: [aStream print: self hash]
	    ifFalse: [aStream nextPutAll: self name]
    ]

    printOn: aStream [
	<category: 'printing'>
	super printOn: aStream.
	aStream nextPut: $(.
	self printNameOn: aStream.
	aStream nextPut: $)
    ]

    propertyAt: aKey [
	"Answer the property value associated with aKey."

	<category: 'accessing-properties'>
	^self propertyAt: aKey ifAbsent: [self error: 'Property not found']
    ]

    propertyAt: aKey ifAbsent: aBlock [
	"Answer the property value associated with aKey or, if aKey isn't found, answer the result of evaluating aBlock."

	<category: 'accessing-properties'>
	^properties isNil 
	    ifTrue: [aBlock value]
	    ifFalse: [properties at: aKey ifAbsent: aBlock]
    ]

    propertyAt: aKey ifAbsentPut: aBlock [
	"Answer the property associated with aKey or, if aKey isn't found store the result of evaluating aBlock as new value."

	<category: 'accessing-properties'>
	^self propertyAt: aKey ifAbsent: [self propertyAt: aKey put: aBlock value]
    ]

    propertyAt: aKey put: anObject [
	"Set the property at aKey to be anObject. If aKey is not found, create a new entry for aKey and set is value to anObject. Answer anObject."

	<category: 'accessing-properties'>
	^(properties ifNil: [properties := Dictionary new: 1]) at: aKey
	    put: anObject
    ]

    removeProperty: aKey [
	"Remove the property with aKey. Answer the property or raise an error if aKey isn't found."

	<category: 'accessing-properties'>
	^self removeProperty: aKey ifAbsent: [self error: 'Property not found']
    ]

    removeProperty: aKey ifAbsent: aBlock [
	"Remove the property with aKey. Answer the value or, if aKey isn't found, answer the result of evaluating aBlock."

	<category: 'accessing-properties'>
	| answer |
	properties isNil ifTrue: [^aBlock value].
	answer := properties removeKey: aKey ifAbsent: aBlock.
	properties isEmpty ifTrue: [properties := nil].
	^answer
    ]

    separatedBy: aParser [
	"Answer a new parser that parses the receiver one or more times, separated by aParser."

	<category: 'operations-convenience'>
	^(PPSequenceParser with: self
	    with: (PPSequenceParser with: aParser with: self) star) ==> 
		    [:nodes | 
		    | result |
		    result := Array new: 2 * nodes second size + 1.
		    result at: 1 put: nodes first.
		    nodes second keysAndValuesDo: 
			    [:index :pair | 
			    result 
				replaceFrom: 2 * index
				to: 2 * index + 1
				with: pair
				startingAt: 1].
		    result]
    ]

    star [
	"Answer a new parser that parses the receiver zero or more times. This is a greedy and blind implementation that tries to consume as much input as possible and it does not consider what comes afterwards."

	<category: 'operations'>
	^PPRepeatingParser on: self
    ]

    starGreedy: aParser [
	"Answer a new parser that parses the receiver zero or more times until it reaches aParser. This is a greedy non-blind implementation of the star operator. aParser is not consumed."

	<category: 'operations'>
	| parser |
	parser := PPChoiceParser new.
	parser setParsers: (Array 
		    with: (self , parser map: 
				[:each :rest | 
				rest
				    addFirst: each;
				    yourself])
		    with: aParser and ==> [:each | OrderedCollection new]).
	^parser ==> [:rest | rest asArray]
    ]

    starLazy: aParser [
	"Answer a new parser that parses the receiver zero or more times until it reaches aParser. This is a lazy non-blind implementation of the star operator. aParser is not consumed."

	<category: 'operations'>
	| parser |
	parser := PPChoiceParser new.
	parser 
	    setParsers: (Array with: aParser and ==> [:each | OrderedCollection new]
		    with: (self , parser map: 
				[:each :rest | 
				rest
				    addFirst: each;
				    yourself])).
	^parser ==> [:rest | rest asArray]
    ]

    token [
	"Answer a new parser that transforms the input to a token."

	<category: 'operations-mapping'>
	^PPTokenParser on: self
    ]

    token: aTokenClass [
	"Answer a new parser that transforms the input to a token of class aTokenClass."

	<category: 'operations-mapping'>
	^self token tokenClass: aTokenClass
    ]

    trim [
	"Answer a new parser that consumes spaces before and after the receiving parser."

	<category: 'operations-mapping'>
	^self trimSpaces
    ]

    trimBlanks [
	"Answer a new parser that consumes blanks before and after the receiving parser."

	<category: 'operations-mapping'>
	^PPTrimmingParser on: self trimmer: #blank asParser
    ]

    trimSpaces [
	"Answer a new parser that consumes spaces before and after the receiving parser."

	<category: 'operations-mapping'>
	^PPTrimmingParser on: self trimmer: #space asParser
    ]

    wrapped [
	"Answer a new parser that is simply wrapped."

	<category: 'operations'>
	^PPDelegateParser on: self
    ]

    | aParser [
	"Answer a new parser that either parses the receiver or aParser. Fail if both pass or fail (exclusive choice, unordered choice)."

	<category: 'operations'>
	^(self not , aParser) / (aParser not , self) ==> #second
    ]
]



PPParser subclass: PPDelegateParser [
    | parser |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that delegates to another parser.

Instance Variables:
	parser	<PPParser>	The parser to delegate to.'>

    PPDelegateParser class >> on: aParser [
	<category: 'instance creation'>
	^self new setParser: aParser
    ]

    children [
	<category: 'accessing'>
	^Array with: parser
    ]

    parseOn: aStream [
	<category: 'parsing'>
	^parser parseOn: aStream
    ]

    setParser: aParser [
	<category: 'initialization'>
	parser := aParser
    ]
]



PPDelegateParser subclass: PPActionParser [
    | block |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that performs an action block with the successful parse result of the delegate.

Instance Variables:
	block	<BlockClosure>	The action block to be executed.
'>

    PPActionParser class >> on: aParser block: aBlock [
	<category: 'instance creation'>
	^(self on: aParser) setBlock: aBlock
    ]

    block [
	"Answer the action block of the receiver."

	<category: 'accessing'>
	^block
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| element |
	^(element := super parseOn: aStream) isPetitFailure 
	    ifFalse: [block value: element]
	    ifTrue: [element]
    ]

    setBlock: aBlock [
	<category: 'initialization'>
	block := aBlock
    ]
]



PPActionParser subclass: PPWrappingParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that performs an action block upon activation with the stream and a continuation block.'>

    parseOn: aStream [
	<category: 'parsing'>
	^block value: aStream value: [parser parseOn: aStream]
    ]
]



PPDelegateParser subclass: PPAndParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'The and-predicate, a parser that succeeds whenever its delegate does, but consumes the input stream [Parr 1994, 1995].'>

    and [
	<category: 'operations'>
	^self
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| element position |
	position := aStream position.
	element := super parseOn: aStream.
	aStream position: position.
	^element
    ]
]



PPDelegateParser subclass: PPCompositeParser [
    
    <category: 'PetitParser-Tools'>
    <comment: 'A PPCompositeParser is composed parser built from various primitive parsers. 

Every production in the receiver is specified as a method that returns its parser. Note that every production requires an instance variable of the same name, otherwise the production is not cached and cannot be used in recursive grammars. Productions should refer to each other by reading the respective inst-var. Note: these inst-vars are typically not written, as the assignment happens in the initialize method using reflection.

The start production is defined in the method start. It is aliased to the inst-var parser defined in the superclass of PPCompositeParser.'>

    PPCompositeParser class >> ignoredNames [
	"Answer a collection of instance-variables that should not be automatically initialized with productions, but that are used internal to the composite parser."

	<category: 'accessing'>
	^PPCompositeParser allInstVarNames
    ]

    PPCompositeParser class >> new [
	"Answer a new parser starting at the default start symbol."

	<category: 'instance creation'>
	^self newStartingAt: self startSymbol
    ]

    PPCompositeParser class >> newStartingAt: aSymbol [
	"Answer a new parser starting at aSymbol."

	<category: 'instance creation'>
	^self basicNew initializeStartingAt: aSymbol
    ]

    PPCompositeParser class >> parse: anObject [
	<category: 'parsing'>
	^self parse: anObject startingAt: self startSymbol
    ]

    PPCompositeParser class >> parse: anObject onError: aBlock [
	<category: 'parsing'>
	^self 
	    parse: anObject
	    startingAt: self startSymbol
	    onError: aBlock
    ]

    PPCompositeParser class >> parse: anObject startingAt: aSymbol [
	<category: 'parsing'>
	^(self newStartingAt: aSymbol) parse: anObject
    ]

    PPCompositeParser class >> parse: anObject startingAt: aSymbol onError: aBlock [
	<category: 'parsing'>
	^(self newStartingAt: aSymbol) parse: anObject onError: aBlock
    ]

    PPCompositeParser class >> startSymbol [
	"Answer the method that represents the default start symbol."

	<category: 'accessing'>
	^#start
    ]

    initializeStartingAt: aSymbol [
	<category: 'initialization'>
	| allVariableNames ignoredVariableNames productionIndexesAndNames |
	self initialize.

	"find all the productions that need to be initialized"
	allVariableNames := self class allInstVarNames.
	ignoredVariableNames := self class ignoredNames.
	productionIndexesAndNames := ((1 to: self class instSize) 
		    collect: [:index | index -> (allVariableNames at: index) asSymbol]) 
			reject: [:assoc | ignoredVariableNames includes: assoc value asString].

	"initialize productions with an undefined parser to be replaced later"
	parser := PPUnresolvedParser named: aSymbol.
	productionIndexesAndNames 
	    do: [:assoc | self instVarAt: assoc key put: (PPUnresolvedParser named: assoc value)].
	parser := self perform: aSymbol.

	"resolve unresolved parsers with their actual implementation"
	productionIndexesAndNames do: 
		[:assoc | 
		(self respondsTo: assoc value) 
		    ifFalse: [self error: 'Unable to initialize ' , assoc value printString]
		    ifTrue: [(self instVarAt: assoc key) def: (self perform: assoc value)]]
    ]

    productionAt: aSymbol [
	"Answer the production named aSymbol."

	<category: 'querying'>
	^self productionAt: aSymbol ifAbsent: [nil]
    ]

    productionAt: aSymbol ifAbsent: aBlock [
	"Answer the production named aSymbol, if there is no such production answer the result of evaluating aBlock."

	<category: 'querying'>
	(self class ignoredNames includes: aSymbol asString) 
	    ifTrue: [^aBlock value].
	self class startSymbol = aSymbol ifTrue: [^parser].
	^self instVarAt: (self class allInstVarNames indexOf: aSymbol asString
		    ifAbsent: [^aBlock value])
    ]

    start [
	"Answer the production to start this parser with."

	<category: 'accessing'>
	self subclassResponsibility
    ]
]



PPDelegateParser subclass: PPEndOfInputParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that succeeds only at the end of the input stream.'>

    end [
	<category: 'operations'>
	^self
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| position result |
	position := aStream position.
	result := super parseOn: aStream.
	(result isPetitFailure or: [aStream atEnd]) ifTrue: [^result].
	result := PPFailure message: 'end of input expected' at: aStream position.
	aStream position: position.
	^result
    ]
]



PPDelegateParser subclass: PPExpressionParser [
    | operators |
    
    <category: 'PetitParser-Tools'>
    <comment: 'A PPExpressionParser is a parser to conveniently define an expression grammar with prefix, postfix, and left- and right-associative infix operators.

The following code initializes a parser for arithmetic expressions. First we instantiate an expression parser, a simple parser for expressions in parenthesis and a simple parser for integer numbers.

	expression := PPExpressionParser new.
	parens := $( asParser token trim , expression , $) asParser token trim 
		==> [ :nodes | nodes second ].
	integer := #digit asParser plus token trim
		==> [ :token | token value asInteger ].
	
Then we define on what term the expression grammar is built on:

	expression term: parens / integer.
	
Finally we define the operator-groups in descending precedence. Note, that the action blocks receive both, the terms and the parsed operator in the order they appear in the parsed input. 
	
	expression
		group: [ :g |
			g prefix: $- asParser token trim do: [ :op :a | a negated ] ];
		group: [ :g |
			g postfix: ''++'' asParser token trim do: [ :a :op | a + 1 ].
			g postfix: ''--'' asParser token trim do: [ :a :op | a - 1 ] ];
		group: [ :g |
			g right: $^ asParser token trim do: [ :a :op :b | a raisedTo: b ] ];
		group: [ :g |
			g left: $* asParser token trim do: [ :a :op :b | a * b ].
			g left: $/ asParser token trim do: [ :a :op :b | a / b ] ];
		group: [ :g |
			g left: $+ asParser token trim do: [ :a :op :b | a + b ].
			g left: $- asParser token trim do: [ :a :op :b | a - b ] ].
		
After evaluating the above code the ''expression'' is an efficient parser that evaluates examples like:

	expression parse: ''-8++''.
	expression parse: ''1+2*3''.
	expression parse: ''1*2+3''.
	expression parse: ''(1+2)*3''.
	expression parse: ''8/4/2''.
	expression parse: ''8/(4/2)''.
	expression parse: ''2^2^3''.
	expression parse: ''(2^2)^3''.
	
Instance Variables:
	operators	<Dictionary>	The operators defined in the current group.'>

    build: aParser left: aChoiceParser [
	<category: 'private'>
	^(aParser separatedBy: aChoiceParser) foldLeft: 
		[:a :op :b | 
		op first 
		    value: a
		    value: op second
		    value: b]
    ]

    build: aParser postfix: aChoiceParser [
	<category: 'private'>
	^aParser , aChoiceParser star map: 
		[:term :ops | 
		ops inject: term
		    into: [:result :operator | operator first value: result value: operator second]]
    ]

    build: aParser prefix: aChoiceParser [
	<category: 'private'>
	^aChoiceParser star , aParser map: 
		[:ops :term | 
		ops reversed inject: term
		    into: [:result :operator | operator first value: operator second value: result]]
    ]

    build: aParser right: aChoiceParser [
	<category: 'private'>
	^(aParser separatedBy: aChoiceParser) foldRight: 
		[:a :op :b | 
		op first 
		    value: a
		    value: op second
		    value: b]
    ]

    buildOn: aParser [
	<category: 'private'>
	^self buildSelectors inject: aParser
	    into: 
		[:term :selector | 
		| list |
		list := operators at: selector ifAbsent: [#()].
		list isEmpty 
		    ifTrue: [term]
		    ifFalse: 
			[self 
			    perform: selector
			    with: term
			    with: (list size = 1 
				    ifTrue: 
					[list first first 
					    ==> [:operator | Array with: list first second with: operator]]
				    ifFalse: 
					[list inject: PPChoiceParser new
					    into: 
						[:choice :each | 
						choice 
						    / (each first ==> [:operator | Array with: each second with: operator])]])]]
    ]

    buildSelectors [
	<category: 'private'>
	^#(#build:prefix: #build:postfix: #build:right: #build:left:)
    ]

    group: aOneArgumentBlock [
	"Defines a priority group by evaluating aOneArgumentBlock."

	<category: 'specifying'>
	operators := Dictionary new.
	parser := 
		[aOneArgumentBlock value: self.
		self buildOn: parser] 
			ensure: [operators := nil]
    ]

    left: aParser do: aThreeArgumentBlock [
	"Define an operator aParser that is left-associative. Evaluate aThreeArgumentBlock with the first term, the operator, and the second term."

	<category: 'specifying'>
	self 
	    operator: #build:left:
	    parser: aParser
	    do: aThreeArgumentBlock
    ]

    operator: aSymbol parser: aParser do: aBlock [
	<category: 'private'>
	parser isNil 
	    ifTrue: 
		[^self error: 'You did not specify a term when creating the receiver.'].
	operators isNil 
	    ifTrue: 
		[^self 
		    error: 'Use #group: to define precedence groups in descending order.'].
	(operators at: aSymbol ifAbsentPut: [OrderedCollection new]) 
	    addLast: (Array with: aParser asParser with: aBlock)
    ]

    postfix: aParser do: aTwoArgumentBlock [
	"Define a postfix operator aParser. Evaluate aTwoArgumentBlock with the term and the operator."

	<category: 'specifying'>
	self 
	    operator: #build:postfix:
	    parser: aParser
	    do: aTwoArgumentBlock
    ]

    prefix: aParser do: aTwoArgumentBlock [
	"Define a prefix operator aParser. Evaluate aTwoArgumentBlock with the operator and the term."

	<category: 'specifying'>
	self 
	    operator: #build:prefix:
	    parser: aParser
	    do: aTwoArgumentBlock
    ]

    right: aParser do: aThreeArgumentBlock [
	"Define an operator aParser that is right-associative. Evaluate aThreeArgumentBlock with the first term, the operator, and the second term."

	<category: 'specifying'>
	self 
	    operator: #build:right:
	    parser: aParser
	    do: aThreeArgumentBlock
    ]

    term: aParser [
	"Defines the initial term aParser of the receiver."

	<category: 'specifying'>
	parser isNil 
	    ifTrue: [parser := aParser]
	    ifFalse: [self error: 'Unable to redefine the term.']
    ]
]



PPDelegateParser subclass: PPFlattenParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that answers a flat copy of the range my delegate parses.'>

    create: aCollection start: aStartInteger stop: aStopInteger [
	<category: 'hooks'>
	^aCollection copyFrom: aStartInteger to: aStopInteger
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| start element stop |
	start := aStream position.
	element := super parseOn: aStream.
	element isPetitFailure 
	    ifTrue: 
		[aStream position: start.
		^element].
	stop := aStream position.
	^self 
	    create: aStream collection
	    start: start + 1
	    stop: stop
    ]
]



PPFlattenParser subclass: PPTokenParser [
    | tokenClass |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that answers a token of the range my delegate parses.

Instance Variables:
	tokenClass	<PPToken class>	The token sub-class to be used.'>

    create: aCollection start: aStartInteger stop: aStopInteger [
	<category: 'private'>
	^self tokenClass 
	    on: aCollection
	    start: aStartInteger
	    stop: aStopInteger
    ]

    defaultTokenClass [
	<category: 'private'>
	^PPToken
    ]

    initialize [
	<category: 'initialization'>
	tokenClass := self defaultTokenClass
    ]

    tokenClass [
	<category: 'accessing'>
	^tokenClass
    ]

    tokenClass: aTokenClass [
	<category: 'accessing'>
	tokenClass := aTokenClass
    ]
]



PPDelegateParser subclass: PPMemoizedParser [
    | stream buffer |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A memoized parser, for refraining redundant computations.

Instance Variables:
	stream	<PositionableStream>	The stream of the associated memento objects.
	buffer	<Array of: PPMemento>	The buffer of memento objects.
'>

    memoized [
	"Ther is no point in memoizing more than once."

	<category: 'operations'>
	^self
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| memento |
	stream == aStream ifFalse: [self reset: aStream].
	memento := (buffer at: stream position + 1) 
		    ifNil: [buffer at: stream position + 1 put: PPMemento new].
	memento position isNil 
	    ifTrue: 
		[memento result: (stream size - stream position + 2 < memento count 
			    ifTrue: [PPFailure message: 'overflow' at: stream position]
			    ifFalse: 
				[memento increment.
				super parseOn: stream]).
		memento position: stream position]
	    ifFalse: [stream position: memento position].
	^memento result
    ]

    reset: aStream [
	<category: 'private'>
	stream := aStream.
	buffer := Array new: aStream size + 1
    ]
]



PPDelegateParser subclass: PPNotParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'The not-predicate, a parser that succeeds whenever its delegate does not, but consumes no input [Parr 1994, 1995].'>

    not [
	<category: 'operations'>
	^parser
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| element position |
	position := aStream position.
	element := super parseOn: aStream.
	aStream position: position.
	^element isPetitFailure 
	    ifFalse: [PPFailure message: '' at: aStream position]
    ]
]



PPDelegateParser subclass: PPRepeatingParser [
    | min max |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that eagerly parses min to max instances of my delegate. The default instance parses eagerly an infinite number of elements, as min is set to 0 and max to infinity (SmallInteger maxVal).

Instance Variables:
	min	<Integer>	The minimum number of repetitions.
	max	<Integer>	The maximum number of repetitions.'>

    PPRepeatingParser class >> on: aParser [
	<category: 'instance creation'>
	^(super on: aParser) setMin: 0 max: SmallInteger maxVal
    ]

    PPRepeatingParser class >> on: aParser max: aMaxInteger [
	<category: 'instance creation'>
	^(self on: aParser) setMin: 0 max: aMaxInteger
    ]

    PPRepeatingParser class >> on: aParser min: aMinInteger [
	<category: 'instance creation'>
	^(self on: aParser) setMin: aMinInteger max: SmallInteger maxVal
    ]

    PPRepeatingParser class >> on: aParser min: aMinInteger max: aMaxInteger [
	<category: 'instance creation'>
	^(self on: aParser) setMin: aMinInteger max: aMaxInteger
    ]

    max [
	"Answer the maximum number of repetitions."

	<category: 'accessing'>
	^max
    ]

    min [
	"Answer the minimum number of repetitions."

	<category: 'accessing'>
	^min
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| start element elements |
	start := aStream position.
	elements := OrderedCollection new.
	[elements size < min] whileTrue: 
		[(element := super parseOn: aStream) isPetitFailure 
		    ifTrue: 
			[aStream position: start.
			^element].
		elements addLast: element].
	[elements size < max] whileTrue: 
		[(element := super parseOn: aStream) isPetitFailure 
		    ifTrue: [^elements asArray].
		elements addLast: element].
	^elements asArray
    ]

    printOn: aStream [
	<category: 'printing'>
	super printOn: aStream.
	aStream
	    nextPutAll: ' [';
	    print: min;
	    nextPutAll: ', ';
	    nextPutAll: (max = SmallInteger maxVal 
			ifTrue: ['*']
			ifFalse: [max printString]);
	    nextPut: $]
    ]

    setMin: aMinInteger max: aMaxInteger [
	<category: 'initialization'>
	min := aMinInteger.
	max := aMaxInteger
    ]
]



PPDelegateParser subclass: PPTrimmingParser [
    | trimmer |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that silently consumes spaces before and after the delegate parser.'>

    PPTrimmingParser class >> on: aParser trimmer: aTrimParser [
	<category: 'instance creation'>
	^(self new)
	    setParser: aParser;
	    setTrimmer: aTrimParser;
	    yourself
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| position element |
	position := aStream position.
	[(trimmer parseOn: aStream) isPetitFailure] whileFalse.
	element := super parseOn: aStream.
	element isPetitFailure 
	    ifTrue: 
		[aStream position: position.
		^element].
	[(trimmer parseOn: aStream) isPetitFailure] whileFalse.
	^element
    ]

    setTrimmer: aParser [
	<category: 'initialization'>
	trimmer := aParser
    ]

    trim [
	"There is no point in trimming more than once."

	<category: 'operations'>
	^self
    ]
]



PPParser subclass: PPEpsilonParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that consumes nothing and always succeeds.'>

    parseOn: aStream [
	<category: 'parsing'>
	^nil
    ]
]



PPParser subclass: PPFailingParser [
    | message |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that consumes nothing and always fails.

Instance Variables:
	message <String>	The failure message.'>

    PPFailingParser class >> message: aString [
	<category: 'instance creation'>
	^self new setMessage: aString
    ]

    message [
	"Answer the error message of the receiving parser."

	<category: 'accessing'>
	^message
    ]

    parseOn: aStream [
	<category: 'parsing'>
	^PPFailure message: message at: aStream position
    ]

    printNameOn: aStream [
	<category: 'printing'>
	super printNameOn: aStream.
	aStream
	    nextPutAll: ', ';
	    print: message
    ]

    setMessage: aString [
	<category: 'initialization'>
	message := aString
    ]
]



PPParser subclass: PPListParser [
    | parsers |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'Abstract parser that parses a list of things in some way (to be specified by the subclasses).

Instance Variables:
	parsers	<SequenceableCollection of: PPParser>	A sequence of other parsers to delegate to.'>

    PPListParser class >> with: aParser [
	<category: 'instance creation'>
	^self withAll: (Array with: aParser)
    ]

    PPListParser class >> with: aFirstParser with: aSecondParser [
	<category: 'instance creation'>
	^self withAll: (Array with: aFirstParser with: aSecondParser)
    ]

    PPListParser class >> withAll: aCollection [
	<category: 'instance creation'>
	^self basicNew setParsers: aCollection
    ]

    children [
	<category: 'accessing'>
	^parsers
    ]

    copyWith: aParser [
	<category: 'copying'>
	^self species withAll: (parsers copyWith: aParser)
    ]

    initialize [
	<category: 'initialization'>
	super initialize.
	self setParsers: #()
    ]

    postCopy [
	<category: 'copying'>
	super postCopy.
	parsers := parsers copy
    ]

    setParsers: aCollection [
	<category: 'initialization'>
	parsers := aCollection asArray
    ]
]



PPListParser subclass: PPChoiceParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that uses the first parser that succeeds.'>

    / aRule [
	<category: 'operations'>
	^self copyWith: aRule
    ]

    parseOn: aStream [
	"This is optimized code that avoids unnecessary block activations, do not change. When all choices fail, the last failure is answered."

	<category: 'parsing'>
	| element |
	1 to: parsers size
	    do: 
		[:index | 
		element := (parsers at: index) parseOn: aStream.
		element isPetitFailure ifFalse: [^element]].
	^element
    ]
]



PPListParser subclass: PPSequenceParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that parses a sequence of parsers.'>

    , aRule [
	<category: 'operations'>
	^self copyWith: aRule
    ]

    map: aBlock [
	<category: 'operations'>
	^self ==> [:nodes | aBlock valueWithArguments: nodes]
    ]

    parseOn: aStream [
	"This is optimized code that avoids unnecessary block activations, do not change."

	<category: 'parsing'>
	| start elements element |
	start := aStream position.
	elements := Array new: parsers size.
	1 to: parsers size
	    do: 
		[:index | 
		element := (parsers at: index) parseOn: aStream.
		element isPetitFailure 
		    ifTrue: 
			[aStream position: start.
			^element].
		elements at: index put: element].
	^elements
    ]

    permutation: anArrayOfIntegers [
	"Answer a permutation of the receivers sequence."

	<category: 'operations'>
	anArrayOfIntegers do: 
		[:index | 
		(index isInteger and: [index between: 1 and: parsers size]) 
		    ifFalse: [self error: 'Invalid permutation index: ' , index printString]].
	^self ==> [:nodes | anArrayOfIntegers collect: [:index | nodes at: index]]
    ]
]



PPParser subclass: PPLiteralParser [
    | literal message |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'Abstract literal parser that parses some kind of literal type (to be specified by subclasses).

Instance Variables:
	literal	<Object>	The literal object to be parsed.
	message	<String>	The error message to be generated.
'>

    PPLiteralParser class >> on: anObject [
	<category: 'instance creation'>
	^self on: anObject message: anObject printString , ' expected'
    ]

    PPLiteralParser class >> on: anObject message: aString [
	<category: 'instance creation'>
	^self new initializeOn: anObject message: aString
    ]

    caseInsensitive [
	"Answer a parser that can parse the receiver case-insensitive."

	<category: 'operators'>
	self subclassResponsibility
    ]

    initializeOn: anObject message: aString [
	<category: 'initialization'>
	literal := anObject.
	message := aString
    ]

    literal [
	"Answer the parsed literal."

	<category: 'accessing'>
	^literal
    ]

    message [
	"Answer the failure message."

	<category: 'accessing'>
	^message
    ]

    printNameOn: aStream [
	<category: 'printing'>
	super printNameOn: aStream.
	aStream
	    nextPutAll: ', ';
	    print: literal
    ]
]



PPLiteralParser subclass: PPLiteralObjectParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that accepts a single literal object, such as a character. This is the same as the predicate parser ''PPPredicateParser expect: literal'' but slightly more efficient.'>

    caseInsensitive [
	"Answer a parser that can parse the receiver case-insensitive."

	<category: 'operators'>
	^PPPredicateObjectParser on: [:value | literal sameAs: value]
	    message: message
    ]

    parseOn: aStream [
	<category: 'parsing'>
	^(aStream atEnd not and: [aStream peek = literal]) 
	    ifFalse: [PPFailure message: message at: aStream position]
	    ifTrue: [aStream next]
    ]
]



PPLiteralParser subclass: PPLiteralSequenceParser [
    | size |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser accepts a sequence of literal objects, such as a String. This is an optimization to avoid having to compose longer sequences from PPSequenceParser.'>

    caseInsensitive [
	"Answer a parser that can parse the receiver case-insensitive."

	<category: 'operators'>
	^PPPredicateSequenceParser 
	    on: [:value | literal sameAs: value]
	    message: message
	    size: size
    ]

    initializeOn: anObject message: aString [
	<category: 'initialization'>
	super initializeOn: anObject message: aString.
	size := literal size
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| position result |
	position := aStream position.
	result := aStream next: size.
	result = literal ifTrue: [^result].
	aStream position: position.
	^PPFailure message: message at: aStream position
    ]
]



PPParser subclass: PPPluggableParser [
    | block |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A pluggable parser that passes the parser stream into a block. This enables users to perform manual parsing or to embed other parser frameworks into PetitParser.

Instance Variables:
	block	<BlockClosure>	The pluggable one-argument block.
'>

    PPPluggableParser class >> on: aBlock [
	<category: 'instance creation'>
	^self new initializeOn: aBlock
    ]

    block [
	"Answer the pluggable block."

	<category: 'accessing'>
	^block
    ]

    initializeOn: aBlock [
	<category: 'initialization'>
	block := aBlock
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| position result |
	position := aStream position.
	result := block value: aStream.
	result isPetitFailure ifTrue: [aStream position: position].
	^result
    ]
]



PPParser subclass: PPPredicateParser [
    | predicate predicateMessage negated negatedMessage |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'An abstract parser that accepts if a given predicate holds.

Instance Variables:
	predicate	<BlockClosure>	The block testing for the predicate.
	predicateMessage	<String>	The error message of the predicate.
	negated	<BlockClosure>	The block testing for the negation of the predicate.
	negatedMessage	<String>	The error message of the negated predicate.'>

    block [
	"Answer the predicate block of the receiver."

	<category: 'accessing'>
	^predicate
    ]

    message [
	"Answer the failure message."

	<category: 'accessing'>
	^predicateMessage
    ]

    printNameOn: aStream [
	<category: 'printing'>
	super printNameOn: aStream.
	aStream
	    nextPutAll: ', ';
	    print: predicateMessage
    ]
]



PPPredicateParser subclass: PPPredicateObjectParser [
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that accepts if a given predicate on one element of the input sequence holds.'>

    PPPredicateObjectParser class >> any [
	<category: 'factory-objects'>
	^self 
	    on: [:each | true]
	    message: 'input expected'
	    negated: [:each | false]
	    message: 'no input expected'
    ]

    PPPredicateObjectParser class >> anyExceptAnyOf: aCollectionOfChars [
	<category: 'factory-objects'>
	^self 
	    on: [:each | (aCollectionOfChars includes: each) not]
	    message: 'any except ' , aCollectionOfChars printString , ' expected'
	    negated: [:each | aCollectionOfChars includes: each]
	    message: aCollectionOfChars printString , ' not expected'
    ]

    PPPredicateObjectParser class >> anyOf: anArray [
	<category: 'factory-objects'>
	^self 
	    on: [:each | anArray includes: each]
	    message: 'any of ' , anArray printString , ' expected'
	    negated: [:each | (anArray includes: each) not]
	    message: 'none of ' , anArray printString , 'expected'
    ]

    PPPredicateObjectParser class >> between: min and: max [
	<category: 'factory-objects'>
	^self 
	    on: [:each | each >= min and: [each <= max]]
	    message: min printString , '..' , max printString , ' expected'
	    negated: [:each | each < min or: [each > max]]
	    message: min printString , '..' , max printString , ' not expected'
    ]

    PPPredicateObjectParser class >> blank [
	<category: 'factory-chars'>
	^self anyOf: (String with: Character space with: Character tab)
    ]

    PPPredicateObjectParser class >> char: aCharacter [
	<category: 'factory-chars'>
	^self expect: aCharacter
    ]

    PPPredicateObjectParser class >> control [
	<category: 'factory-chars'>
	^self 
	    on: [:char | char asInteger < 32]
	    message: 'control character expected'
	    negated: [:char | char asInteger >= 32]
	    message: 'no control character expected'
    ]

    PPPredicateObjectParser class >> cr [
	<category: 'factory-chars'>
	^self char: Character cr
    ]

    PPPredicateObjectParser class >> digit [
	<category: 'factory-chars'>
	^self 
	    on: [:char | char isDigit]
	    message: 'digit expected'
	    negated: [:char | char isDigit not]
	    message: 'no digit expected'
    ]

    PPPredicateObjectParser class >> expect: anObject [
	<category: 'factory-objects'>
	^self 
	    on: [:each | each = anObject]
	    message: anObject printString , ' expected'
	    negated: [:each | each ~= anObject]
	    message: anObject printString , ' not expected'
    ]

    PPPredicateObjectParser class >> hex [
	<category: 'factory-chars'>
	^self on: 
		[:char | 
		(char between: $0 and: $9) 
		    or: [(char between: $a and: $f) or: [char between: $A and: $F]]]
	    message: 'hex digit expected'
    ]

    PPPredicateObjectParser class >> letter [
	<category: 'factory-chars'>
	^self 
	    on: [:char | char isLetter]
	    message: 'letter expected'
	    negated: [:char | char isLetter not]
	    message: 'no letter expected'
    ]

    PPPredicateObjectParser class >> lf [
	<category: 'factory-chars'>
	^self char: Character lf
    ]

    PPPredicateObjectParser class >> lowercase [
	<category: 'factory-chars'>
	^self 
	    on: [:char | char isLowercase]
	    message: 'lowercase letter expected'
	    negated: [:char | char isLowercase not]
	    message: 'no lowercase letter expected'
    ]

    PPPredicateObjectParser class >> newline [
	<category: 'factory-chars'>
	^self anyOf: (String with: Character cr with: Character lf)
    ]

    PPPredicateObjectParser class >> on: aBlock message: aString [
	<category: 'instance creation'>
	^self 
	    on: aBlock
	    message: aString
	    negated: [:each | (aBlock value: each) not]
	    message: 'no ' , aString
    ]

    PPPredicateObjectParser class >> on: aBlock message: aString negated: aNegatedBlock message: aNegatedString [
	<category: 'instance creation'>
	^self new 
	    initializeOn: aBlock
	    message: aString
	    negated: aNegatedBlock
	    message: aNegatedString
    ]

    PPPredicateObjectParser class >> punctuation [
	<category: 'factory-chars'>
	^self anyOf: '.,"''?!;:#$%&()*+-/<>=@[]\^_{}|~'
    ]

    PPPredicateObjectParser class >> space [
	<category: 'factory-chars'>
	^self 
	    on: [:char | char isSeparator]
	    message: 'separator expected'
	    negated: [:char | char isSeparator not]
	    message: 'no separator expected'
    ]

    PPPredicateObjectParser class >> tab [
	<category: 'factory-chars'>
	^self char: Character tab
    ]

    PPPredicateObjectParser class >> uppercase [
	<category: 'factory-chars'>
	^self 
	    on: [:char | char isUppercase]
	    message: 'uppercase letter expected'
	    negated: [:char | char isUppercase not]
	    message: 'no uppercase letter expected'
    ]

    PPPredicateObjectParser class >> word [
	<category: 'factory-chars'>
	^self 
	    on: [:each | each isAlphaNumeric]
	    message: 'letter or digit expected'
	    negated: [:each | each isAlphaNumeric not]
	    message: 'no letter or digit expected'
    ]

    initializeOn: aBlock message: aString negated: aNegatedBlock message: aNegatedString [
	<category: 'initialization'>
	predicate := aBlock.
	predicateMessage := aString.
	negated := aNegatedBlock.
	negatedMessage := aNegatedString
    ]

    negate [
	"Answer a parser that is the negation of the receiving predicate parser."

	<category: 'operators'>
	^self class 
	    on: negated
	    message: negatedMessage
	    negated: predicate
	    message: predicateMessage
    ]

    parseOn: aStream [
	<category: 'parsing'>
	^(aStream atEnd not and: [predicate value: aStream peek]) 
	    ifFalse: [PPFailure message: predicateMessage at: aStream position]
	    ifTrue: [aStream next]
    ]
]



PPPredicateParser subclass: PPPredicateSequenceParser [
    | size |
    
    <category: 'PetitParser-Parsers'>
    <comment: 'A parser that accepts if a given predicate on an arbitrary number of elements of the input sequence holds.

Instance Variables:
	size	<Integer>	The number of elements to consume.'>

    PPPredicateSequenceParser class >> on: aBlock message: aString negated: aNegatedBlock message: aNegatedString size: anInteger [
	<category: 'instance creation'>
	^self new 
	    initializeOn: aBlock
	    message: aString
	    negated: aNegatedBlock
	    message: aNegatedString
	    size: anInteger
    ]

    PPPredicateSequenceParser class >> on: aBlock message: aString size: anInteger [
	<category: 'instance creation'>
	^self 
	    on: aBlock
	    message: aString
	    negated: [:each | (aBlock value: each) not]
	    message: 'no ' , aString
	    size: anInteger
    ]

    initializeOn: aBlock message: aString negated: aNegatedBlock message: aNegatedString size: anInteger [
	<category: 'initialization'>
	predicate := aBlock.
	predicateMessage := aString.
	negated := aNegatedBlock.
	negatedMessage := aNegatedString.
	size := anInteger
    ]

    negate [
	"Answer a parser that is the negation of the receiving predicate parser."

	<category: 'operators'>
	^self class 
	    on: negated
	    message: negatedMessage
	    negated: predicate
	    message: predicateMessage
	    size: size
    ]

    parseOn: aStream [
	<category: 'parsing'>
	| position result |
	position := aStream position.
	result := aStream next: size.
	(result size = size and: [predicate value: result]) ifTrue: [^result].
	aStream position: position.
	^PPFailure message: predicateMessage at: aStream position
    ]

    size [
	"Answer the sequence size of the receiver."

	<category: 'accessing'>
	^size
    ]
]



PPParser subclass: PPUnresolvedParser [
    
    <category: 'PetitParser-Tools'>
    <comment: 'This is a temporary placeholder or forward reference to a parser that has not been defined yet. If everything goes well it will eventually be replaced with the real parser instance.'>

    isUnresolved [
	<category: 'testing'>
	^true
    ]

    parseOn: aStream [
	<category: 'parsing'>
	self error: self printString , ' need to be resolved before execution.'
    ]
]



Object subclass: PPToken [
    | collection start stop |
    
    <category: 'PetitParser-Core'>
    <comment: 'PPToken represents a parsed part of the input stream. Contrary to a simple String it remembers where it came from, the original collection and its start and stop position.

Instance Variables:
	collection	<SequenceableCollection>	The collection this token comes from.
	start	<Integer>	The start position in the collection.
	stop	<Integer>	The stop position in the collection.'>

    PPToken class >> new [
	<category: 'instance creation'>
	self error: 'Token can only be created using a dedicated constructor.'
    ]

    PPToken class >> on: aSequenceableCollection [
	<category: 'instance creation'>
	^self 
	    on: aSequenceableCollection
	    start: 1
	    stop: aSequenceableCollection size
    ]

    PPToken class >> on: aSequenceableCollection start: aStartInteger stop: aStopInteger [
	<category: 'instance creation'>
	^self basicNew 
	    initializeOn: aSequenceableCollection
	    start: aStartInteger
	    stop: aStopInteger
    ]

    = anObject [
	<category: 'comparing'>
	^self class = anObject class and: [self value = anObject value]
    ]

    collection [
	"Answer the underlying collection of this token."

	<category: 'accessing'>
	^collection
    ]

    column [
	"Answer the column number of this token in the underlying collection."

	<category: 'querying'>
	| position |
	position := 0.
	((self newline 
	    , 
		[:stream | 
		start <= stream position ifTrue: [^start - position].
		position := stream position] 
			asParser) 
		/ #any asParser) star 
	    parse: collection.
	^start - position
    ]

    copyFrom: aStartInteger to: aStopInteger [
	<category: 'copying'>
	^self class 
	    on: collection
	    start: start + aStartInteger - 1
	    stop: stop + aStopInteger - 3
    ]

    hash [
	<category: 'comparing'>
	^self value hash
    ]

    initializeOn: aSequenceableCollection start: aStartInteger stop: aStopInteger [
	<category: 'initialization'>
	collection := aSequenceableCollection.
	start := aStartInteger.
	stop := aStopInteger
    ]

    line [
	"Answer the line number of this token in the underlying collection."

	<category: 'querying'>
	| line |
	line := 1.
	((self newline 
	    , 
		[:stream | 
		start <= stream position ifTrue: [^line].
		line := line + 1] asParser) 
		/ #any asParser) star 
	    parse: collection.
	^line
    ]

    newline [
	"Parser a platform independent newline sequence. LF: Unix, CR+LF: Windows, and CR: Apple."

	<category: 'private'>
	^Character lf asParser 
	    / (Character cr asParser , Character lf asParser optional)
    ]

    printOn: aStream [
	<category: 'printing'>
	super printOn: aStream.
	aStream
	    nextPut: $(;
	    nextPutAll: self value;
	    nextPut: $)
    ]

    size [
	"Answer the size of this token."

	<category: 'accessing'>
	^stop - start + 1
    ]

    start [
	"Answer the start position of this token in the underlying collection."

	<category: 'accessing'>
	^start
    ]

    stop [
	"Answer the stop position of this token in the underlying collection."

	<category: 'accessing'>
	^stop
    ]

    value [
	"Answer the contents of this token."

	<category: 'accessing'>
	^collection copyFrom: start to: stop
    ]
]

